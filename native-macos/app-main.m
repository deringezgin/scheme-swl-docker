// Native application entry point. Chez runs in this process, inside SWL.app.
#import <Cocoa/Cocoa.h>
#include <unistd.h>
#include <sys/stat.h>
#include "scheme.h"

static void environment(const char *name, NSString *value) {
    if (setenv(name, value.fileSystemRepresentation, 1) != 0) {
        perror(name);
        exit(1);
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        umask(0077);
        NSFileManager *files = NSFileManager.defaultManager;
        NSString *resources = NSBundle.mainBundle.resourcePath;
        NSString *runtime = [resources stringByAppendingPathComponent:@"runtime"];
        NSString *heaps = [runtime stringByAppendingPathComponent:@"lib/csv10.4.1/arm64osx"];
        NSString *swl = [runtime stringByAppendingPathComponent:@"lib/swl1.3/arm64osx"];
        NSString *boot = [swl stringByAppendingPathComponent:@"swl.boot"];
        if (![files fileExistsAtPath:boot]) {
            fprintf(stderr, "SWL.app is incomplete: missing %s\n", boot.fileSystemRepresentation);
            return 1;
        }
        environment("SWL_RUNTIME_ROOT", runtime);
        environment("SCHEMEHEAPDIRS", heaps);
        environment("SWL_LIBRARY", swl);
        environment("SWL_ROOT", [runtime stringByAppendingPathComponent:@"lib/swl1.3/lib"]);
        environment("TCL_LIBRARY", [runtime stringByAppendingPathComponent:@"lib/tcl8.6"]);
        environment("TK_LIBRARY", [runtime stringByAppendingPathComponent:@"lib/tk8.6"]);
        if (!getenv("SWL_PREFS_DIR"))
            environment("SWL_PREFS_DIR", [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Application Support/SWL"]);
        NSString *preferences = [NSString stringWithUTF8String:getenv("SWL_PREFS_DIR")];
        NSError *error = nil;
        if (![files createDirectoryAtPath:preferences withIntermediateDirectories:YES attributes:nil error:&error]) {
            fprintf(stderr, "Cannot create SWL preferences: %s\n", error.localizedDescription.UTF8String);
            return 1;
        }

        BOOL check = argc == 2 && strcmp(argv[1], "--check-runtime") == 0;
        if (!check && !isatty(STDERR_FILENO) && !getenv("SWL_STDIO")) {
            NSString *logs = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Logs/SWL"];
            [files createDirectoryAtPath:logs withIntermediateDirectories:YES attributes:nil error:nil];
            NSString *log = [logs stringByAppendingPathComponent:@"swl.log"];
            freopen(log.fileSystemRepresentation, "a", stdout);
            freopen(log.fileSystemRepresentation, "a", stderr);
        }

        const char **arguments = calloc((size_t)argc + 1, sizeof(char *));
        if (!arguments) return 1;
        int count = 1;
        arguments[0] = argv[0];
        for (int i = 1; i < argc; i++)
            if (strncmp(argv[i], "-psn_", 5) != 0) arguments[count++] = argv[i];
        if (count == 2 && !check) {
            NSString *path = [NSString stringWithUTF8String:arguments[1]];
            if ([files fileExistsAtPath:path]) {
                if (!path.isAbsolutePath) path = [files.currentDirectoryPath stringByAppendingPathComponent:path];
                path = path.stringByStandardizingPath;
                arguments[1] = strdup(path.fileSystemRepresentation);
                chdir(path.stringByDeletingLastPathComponent.fileSystemRepresentation);
            }
        } else if (count == 1) {
            chdir(NSHomeDirectory().fileSystemRepresentation);
        }

        Sscheme_init(NULL);
        Sregister_boot_file([[heaps stringByAppendingPathComponent:@"petite.boot"] fileSystemRepresentation]);
        Sregister_boot_file([[heaps stringByAppendingPathComponent:@"scheme.boot"] fileSystemRepresentation]);
        Sregister_boot_file(boot.fileSystemRepresentation);
        Sbuild_heap(argv[0], NULL);
        if (check) {
            puts("SWL_ARM64_BOOT_OK");
            Sscheme_deinit();
            free(arguments);
            return 0;
        }
        int status = Sscheme_start(count, arguments);
        Sscheme_deinit();
        free(arguments);
        return status;
    }
}
