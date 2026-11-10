#lang eopl
;Autores: Samuel Esteban Peña Jaramillo 2477399

#|
  Taller 3 — Cauca con referencias y tipos.
  TAD ambiente y valor procedimiento.

  Las dos definiciones van en el mismo módulo porque se nombran entre
  sí: el campo del ambiente dentro de una clausura pide ambiente?, y
  apply-env construye una clausura cuando resuelve un nombre ligado por
  letrec. Separarlas deja uno de los dos campos sin predicado.

  Faltan los dos datatypes:
    - ambiente, con las variantes ambiente-vacio, ambiente-extendido y
      ambiente-recursivo
    - procval, con la variante de la clausura: los parámetros, el cuerpo
      y el ambiente donde se creó

  El cuerpo de una clausura es una expresion?, que viene de sintaxis.rkt.
|#

(require "sintaxis.rkt")

;; Datatype ambiente
(define-datatype ambiente ambiente?
  ;; ambiente-vacio: final de la cadena de ambientes.
  (ambiente-vacio)
  ;; ambiente-extendido: liga listas de identificadores a valores (let, apply, applyref).
  (ambiente-extendido
   (ids (list-of symbol?))
   (valores list?)
   (env ambiente?))
   ;; ambiente-recursivo: guarda nombres, listas de parametros y cuerpos sin evaluar para procedimientos declarados con letrec.
  (ambiente-recursivo
   (proc-names (list-of symbol?))
   (idss (list-of (list-of symbol?)))
   (bodies (list-of expresion?))
   (env ambiente?)))

;; Datatype procval, se encarga de representar un procedimiento como una cerradura que empaqueta la lista de parametros formales, el cuerpo sin evaluar y el ambiente lexico donde fue creado. 
(define-datatype procval procval?
  (cerradura
   (ids (list-of symbol?))
   (body expresion?)
   (env ambiente?)))

;; posicion-de 
;; symbol x lista de symbol -> int | #f
;; Recorre la lista de identificadores buscando la primera aparicion de id. Si lo encuentra devuelve su indice o #f si no esta.
(define posicion-de
  (lambda (id ids)
    (letrec ((buscar (lambda (lst i)
                       (cond
                         ((null? lst) #f)
                         ((eqv? (car lst) id) i)
                         (else (buscar (cdr lst) (+ i 1)))))))
      (buscar ids 0))))

;; apply-env
;; ambiente x symbol -> valor
;; Busca el identificador en el ambiente respetando el shadowing de las ligaduras mas recientes.Si encuentra el nombre en un ambiente-recursivo, arma la cerradura pasandole ese mismo ambiente recursivo. Si llega al vacio levanta eopl:error.
(define apply-env
  (lambda (env id)
    (cases ambiente env
      (ambiente-vacio ()
        (eopl:error 'apply-env
                    "Variable no ligada: ~s"
                    id))

      (ambiente-extendido (ids valores env-padre)
        (let ((pos (posicion-de id ids)))
          (if (number? pos)
              (list-ref valores pos)
              (apply-env env-padre id))))

      (ambiente-recursivo (proc-names idss bodies env-padre)
        (let ((pos (posicion-de id proc-names)))
          (if (number? pos)
              ;; Armamos la cerradura en el momento de la busqueda entregandole envpara soportar recursion mutua.
              (cerradura (list-ref idss pos)
                         (list-ref bodies pos)
                         env)
              (apply-env env-padre id)))))))

;; ambiente-inicial : -> ambiente
;; El del enunciado: n = 10, m = 3, p = 7, q = 2, r = 5.
(define ambiente-inicial
  (lambda ()
    (ambiente-extendido '(n m p q r)
                        '(10 3 7 2 5)
                        (ambiente-vacio))))

(provide (all-defined-out))
