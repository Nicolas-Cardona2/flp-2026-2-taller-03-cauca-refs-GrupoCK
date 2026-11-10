#lang eopl
;Autores: Samuel Esteban Peña Jaramillo 2477399

#|
  Taller 3 — Cauca con referencias y tipos.
  Primitivas del lenguaje.

  evaluar-primitiva recibe la primitiva del árbol y la lista de valores
  ya evaluados, revisa la cantidad y el tipo de los argumentos y produce
  el resultado. Solo necesita la gramática, no el evaluador.

  Las verificaciones de cantidad y de tipo van aquí, junto a la
  primitiva que las exige, y levantan eopl:error con un mensaje que
  nombre la primitiva.
|#

(require "sintaxis.rkt")

;; Verificacion de tipos y cantidad de argumentos

;; exigir-numeros
;; lista x symbol -> boolean
;; Retorna #t si todos los argumentos son números; si no, levanta eopl:error a nombre de quien hizo la verificación.
(define exigir-numeros
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((number? (car args)) (exigir-numeros (cdr args) quien))
      (else (eopl:error quien "El argumento debe ser un numero: ~s" (car args))))))

;; exigir-enteros
;; lista x symbol -> boolean
;; Retorna #t si todos los argumentos son enteros; si no, levanta error.
(define exigir-enteros
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((integer? (car args)) (exigir-enteros (cdr args) quien))
      (else (eopl:error quien "El argumento debe ser un entero: ~s" (car args))))))

;; exigir-booleanos
;; lista x symbol -> boolean
;; Retorna #t si todos los argumentos son booleanos; si no, levanta error.
(define exigir-booleanos
  (lambda (args quien)
    (cond
      ((null? args) #t)
      ((boolean? (car args)) (exigir-booleanos (cdr args) quien))
      (else (eopl:error quien "El argumento debe ser un booleano: ~s" (car args))))))

;; exigir-cantidad 
;; lista x int x symbol -> boolean
;; Retorna #t si llegaron exactamente n argumentos; si no, levanta error.
(define exigir-cantidad
  (lambda (args n quien)
    (if (= (length args) n)
        #t
        (eopl:error quien "Se esperaban ~s argumento(s) y llegaron ~s" n (length args)))))

;; exigir-minimo 
;; lista x int x symbol -> boolean
;; Retorna #t si llegaron al menos n argumentos; si no, levanta error.
(define exigir-minimo
  (lambda (args n quien)
    (if (>= (length args) n)
        #t
        (eopl:error quien "Se esperaban al menos ~s argumentos y llegaron ~s" n (length args)))))

;; Funciones auxiliares

;; plegar-izquierda 
;; (valor x valor -> valor) x lista -> valor
;; Aplica la operacion binaria de izquierda a derecha sobre una lista no vacia: (op (op a b) c) ...
(define plegar-izquierda
  (lambda (op args)
    (letrec ((plegar (lambda (acc resto)
                       (if (null? resto)
                           acc
                           (plegar (op acc (car resto)) (cdr resto))))))
      (plegar (car args) (cdr args)))))

;; dividir
;; numero x numero -> numero
;; Divide a entre b y levanta eopl:error si b es cero.
(define dividir
  (lambda (a b)
    (if (= b 0)
        (eopl:error '/ "Division por cero")
        (/ a b))))

;; mcd-dos 
;; int x int -> int
;; Saca el maximo comun divisor entre dos enteros usando Euclides y asegura resultado positivo.
(define mcd-dos
  (lambda (a b)
    (letrec ((euclides (lambda (x y)
                         (if (= y 0)
                             x
                             (euclides y (remainder x y))))))
      (euclides (abs a) (abs b)))))

;; mcm-dos 
;; int x int -> int
;; Calcula el minimo comun multiplo entre dos enteros con (|a * b|) / mcd(a, b).
(define mcm-dos
  (lambda (a b)
    (if (or (= a 0) (= b 0))
        0
        (abs (/ (* a b) (mcd-dos a b))))))


;; evaluar-primitiva 
;; primitiva x lista de valores -> valor
;; Verifica la cantidad y el tipo de los argumentos y aplica la primitiva. Se resuelve con cases sobre el datatype primitiva.
(define evaluar-primitiva
  (lambda (prim args)
    (cases primitiva prim
      (sum-prim ()
        (exigir-minimo args 2 '+) (exigir-numeros args '+)
        (plegar-izquierda + args))
      (minus-prim ()
        (exigir-minimo args 2 '-) (exigir-numeros args '-)
        (plegar-izquierda - args))
      (mult-prim ()
        (exigir-minimo args 2 '*) (exigir-numeros args '*)
        (plegar-izquierda * args))
      (div-prim ()
        (exigir-minimo args 2 '/) (exigir-numeros args '/)
        (plegar-izquierda dividir args))
      (add-prim ()
        (exigir-cantidad args 1 'add1) (exigir-numeros args 'add1)
        (+ (car args) 1))
      (sub-prim ()
        (exigir-cantidad args 1 'sub1) (exigir-numeros args 'sub1)
        (- (car args) 1))
      (mayor-prim ()
        (exigir-cantidad args 2 '>) (exigir-numeros args '>)
        (> (car args) (cadr args)))
      (mayorigual-prim ()
        (exigir-cantidad args 2 '>=) (exigir-numeros args '>=)
        (>= (car args) (cadr args)))
      (menor-prim ()
        (exigir-cantidad args 2 '<) (exigir-numeros args '<)
        (< (car args) (cadr args)))
      (menorigual-prim ()
        (exigir-cantidad args 2 '<=) (exigir-numeros args '<=)
        (<= (car args) (cadr args)))
      (igual-prim ()
        (exigir-cantidad args 2 '==) (exigir-numeros args '==)
        (= (car args) (cadr args)))
      (not-prim ()
        (exigir-cantidad args 1 'not) (exigir-booleanos args 'not)
        (not (car args)))
      (and-prim ()
        (exigir-cantidad args 2 'and) (exigir-booleanos args 'and)
        (and (car args) (cadr args)))
      (or-prim ()
        (exigir-cantidad args 2 'or) (exigir-booleanos args 'or)
        (or (car args) (cadr args)))
      (abs-prim ()
        (exigir-cantidad args 1 'abs)
        (exigir-numeros args 'abs)
        (abs (car args)))
      (mcd-prim ()
        (exigir-minimo args 2 'mcd)
        (exigir-enteros args 'mcd)
        (plegar-izquierda mcd-dos args))
      (mcm-prim ()
        (exigir-minimo args 2 'mcm)
        (exigir-enteros args 'mcm)
        (plegar-izquierda mcm-dos args))
      (promedio-prim ()
        (exigir-minimo args 1 'promedio)
        (exigir-numeros args 'promedio)
        (/ (plegar-izquierda + args) (length args)))
      (xor-prim ()
        (exigir-cantidad args 2 'xor)
        (exigir-booleanos args 'xor)
        (not (equal? (car args) (cadr args))))
      (implica-prim ()
        (exigir-cantidad args 2 'implica)
        (exigir-booleanos args 'implica)
        (or (not (car args)) (cadr args)))
      (entre-prim ()
        (exigir-cantidad args 3 'entre)
        (exigir-numeros args 'entre)
        (and (<= (cadr args) (car args)) (<= (car args) (caddr args)))))))

(provide (all-defined-out))
