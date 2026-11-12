#lang eopl
#|
Autores:
Santiago Serrano Morales 2477006
|#

#|
  Taller 3 — Cauca con referencias y tipos.
  Fachada del chequeador.

  El chequeador no evalúa nada: recorre el árbol de sintaxis abstracta
  con cases y consulta un ambiente de tipos. La función de entrada es
  type-of-program, que retorna el tipo del programa o levanta
  eopl:error explicando el conflicto.

  El código vive en src/ y este archivo lo reúne y lo reexporta:

    src/tipos.rkt       comparación de tipos, ambiente de tipos y tipos de las primitivas
    src/chequeador.rkt  type-of, type-of-program y tipo-de-texto

  Los dos leen la gramática de src/sintaxis.rkt, la misma que usa el
  intérprete, así que el árbol y las anotaciones de tipo se declaran una
  sola vez. Como cada módulo exporta lo que define y no reexporta lo que
  importó, esta fachada no vuelve a sacar los nombres de la gramática y
  las pruebas pueden requerir las dos fachadas a la vez.
|#

(require "src/tipos.rkt")
(require "src/chequeador.rkt")

(provide (all-from-out "src/tipos.rkt"
                       "src/chequeador.rkt"))
