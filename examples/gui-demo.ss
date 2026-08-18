; Minimal SWL 1.3 GUI example.

(import swl:oop)
(import swl:macros)
(import swl:generics)
(import swl:option)

(define top
  (create <toplevel> with
    (title: "Scheme/SWL GUI Demo")))

(define canvas
  (create <canvas> top with
    (background-color: (make <rgb> 235 240 248))))

(send canvas set-width! 360)
(send canvas set-height! 220)

(define circle (create <oval> canvas 105 35 255 185))
(set-fill-color! circle (make <rgb> 51 102 204))
(show canvas)

; CI requests a sentinel after the window was constructed.
(let ((sentinel (getenv "SWL_CI_SENTINEL")))
  (when sentinel
    (with-output-to-file sentinel
      (lambda ()
        (display "SWL_1_3_GUI_OK")
        (newline))
      'replace)))
