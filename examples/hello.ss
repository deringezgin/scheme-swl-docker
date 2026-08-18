; Minimal non-GUI Petite Chez Scheme 8.4 example.

(define factorial
  (lambda (n)
    (if (= n 0)
        1
        (* n (factorial (- n 1))))))

(display (scheme-version))
(newline)
(display "factorial(6) = ")
(display (factorial 6))
(newline)
