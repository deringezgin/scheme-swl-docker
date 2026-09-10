(function () {
    "use strict";

    var canvas = document.getElementById("noVNC_canvas");
    var screen = document.getElementById("noVNC_screen");
    var status = document.getElementById("noVNC_status_bar");
    var viewport = document.createElement("div");

    document.documentElement.style.overflow = "hidden";
    screen.style.cssText = "display:flex;flex-direction:column;width:100vw;height:100vh;overflow:hidden;border-radius:0;background:#111";
    status.style.flex = "0 0 auto";
    viewport.style.cssText = "display:flex;align-items:center;justify-content:center;flex:1;min-height:0;overflow:hidden";
    canvas.parentNode.insertBefore(viewport, canvas);
    viewport.appendChild(canvas);
    canvas.style.flex = "0 0 auto";

    function fit() {
        var scale = Math.min(viewport.clientWidth / canvas.width,
                             viewport.clientHeight / canvas.height);
        canvas.style.width = canvas.width * scale + "px";
        canvas.style.height = canvas.height * scale + "px";
    }

    // The legacy viewer assumes an unscaled canvas when mapping pointer events.
    var originalPosition = Util.getEventPosition;
    Util.getEventPosition = function (event, target, scale) {
        if (target !== canvas) {
            return originalPosition(event, target, scale);
        }
        var point = event.changedTouches ? event.changedTouches[0] :
                    event.touches ? event.touches[0] : event;
        var rect = canvas.getBoundingClientRect();
        var x = (point.clientX - rect.left) * canvas.width / rect.width;
        var y = (point.clientY - rect.top) * canvas.height / rect.height;
        return {
            x: Math.max(0, Math.min(canvas.width - 1, x)),
            y: Math.max(0, Math.min(canvas.height - 1, y)),
            realx: x,
            realy: y
        };
    };

    new ResizeObserver(fit).observe(viewport);
    new MutationObserver(fit).observe(canvas, {
        attributes: true,
        attributeFilter: ["width", "height"]
    });
    fit();
}());
