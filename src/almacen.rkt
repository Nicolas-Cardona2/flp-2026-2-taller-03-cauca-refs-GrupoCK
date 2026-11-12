#lang eopl
;Autores: Nicolás Cardona García 2477349 

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD referencia y almacén (Parte 1).

  El módulo no requiere ningún otro: el almacén guarda valores
  cualesquiera y no necesita la gramática.

  La referencia es un tipo abstracto y no un entero desnudo: un programa
  de Cauca no puede fabricar una posición de memoria ni hacer aritmética
  con ella, solo recibirla de newref! y pasarla a deref y setref!.

  El almacén es una lista de valores; la posición de una celda es su
  índice (la primera celda es la 0). Vive en una variable global, el
  único lugar del curso donde se usa set!, y todas las operaciones que
  lo modifican reemplazan la lista completa por otra nueva.

  Invariante que las operaciones tienen que preservar, y que se demuestra
  en la Parte 5:
    1. toda referencia entregada por newref! apunta a una celda existente
    2. el almacén solo crece por newref!
    3. setref! cambia una celda y deja las demás intactas
    4. deref sobre una referencia fuera de rango levanta eopl:error
|#

;; Datatype referencia: envuelve la posición de una celda del almacén.
(define-datatype referencia referencia?
  (a-ref (pos integer?)))

;; el-almacen : lista de valores
;; El almacén global. La celda de posición i es el elemento i de la lista.
(define el-almacen '())

;; empty-store : -> almacen
;; El almacén sin celdas.
(define empty-store
  (lambda ()
    '()))

;; initialize-store! : -> void
;; Deja el almacén vacío. Se llama al empezar cada programa.
(define initialize-store!
  (lambda ()
    (set! el-almacen (empty-store))))

;; posicion-valida? : integer -> boolean
;; Retorna #t si la posición nombra una celda existente del almacén,
;; es decir, si 0 <= pos < tamaño.
(define posicion-valida?
  (lambda (pos)
    (and (>= pos 0) (< pos (length el-almacen)))))

;; reemplazar-celda : lista x integer x valor -> lista
;; retorna una lista igual a lst salvo en la posición pos, que queda con val y supone que pos es una posición válida de lst
(define reemplazar-celda
  (lambda (lst pos val)
    (if (= pos 0)
        (cons val (cdr lst))
        (cons (car lst) (reemplazar-celda (cdr lst) (- pos 1) val)))))

;; newref! : valor -> referencia
;; Agrega una celda con el valor y retorna la referencia que la nombra.
(define newref!
  (lambda (val)
    (let ((pos (length el-almacen)))
      (set! el-almacen (append el-almacen (list val)))
      (a-ref pos))))

;; deref : referencia -> valor
;; Lee la celda. Si la referencia está fuera de rango, levanta eopl:error.
;; no modifica el almacen
(define deref
  (lambda (ref)
    (cases referencia ref
      (a-ref (pos)
             (if (posicion-valida? pos)
                 (list-ref el-almacen pos)
                 (eopl:error 'deref
                             "Referencia fuera de rango: ~s (el almacen tiene ~s celdas)"
                             pos (length el-almacen)))))))

;; setref! : referencia x valor -> void
;; Escribe el valor en la celda y deja las demás intactas, Si la
;; referencia está fuera de rango, levanta eopl:error
(define setref!
  (lambda (ref val)
    (cases referencia ref
      (a-ref (pos)
             (if (posicion-valida? pos)
                 (set! el-almacen (reemplazar-celda el-almacen pos val))
                 (eopl:error 'setref!
                             "Referencia fuera de rango: ~s (el almacen tiene ~s celdas)"
                             pos (length el-almacen)))))))

(provide (all-defined-out))