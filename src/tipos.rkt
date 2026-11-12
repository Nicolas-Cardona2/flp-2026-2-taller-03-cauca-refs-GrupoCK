#lang eopl
#|
Autores:
Santiago Serrano Morales 2477006
|#

#|
  Taller 3 — Cauca con referencias y tipos.
  El tipo y el ambiente de tipos (Parte 3).

  El datatype tipo lo genera la gramática, porque las anotaciones se
  escriben dentro del programa. Aquí van la comparación estructural de
  dos tipos, el texto con que un tipo aparece en los mensajes de error y
  el ambiente de tipos.

  Falta el datatype del ambiente de tipos, con las mismas tres variantes
  del ambiente de valores: tenv-vacio, tenv-extendido y tenv-recursivo.
  La recursiva guarda el tipo declarado de cada procedimiento, que es lo
  que permite chequear el cuerpo de un letrec sin evaluarlo.

  El módulo requiere sintaxis.rkt y ningún otro del intérprete.
|#

(require "sintaxis.rkt")

;; ==========================================================
;; 1. Datatype del ambiente de tipos
;; ==========================================================
;; tenv : datatype
;; Propósito: representar el ambiente de tipos mediante ambientes
;; vacíos, extendidos y recursivos.
;; tenv-vacio: representa el ambiente de tipos vacío.
;; tenv-extendido: asocia identificadores con sus tipos.
;; tenv-recursivo: almacena los nombres y tipos de procedimientos
;; declarados mediante letrec.

(define-datatype tenv tenv?
  (tenv-vacio)

  (tenv-extendido
   (ids (list-of symbol?))
   (tipos list?)
   (env tenv?))

  (tenv-recursivo
   (proc-names (list-of symbol?))
   (proc-tipos list?)
   (env tenv?)))

;; ==========================================================
;; 2. Tipos
;; ==========================================================

;; tipo->texto : tipo -> string
;; La forma en que los tipos aparecen en los mensajes de error:
;; "num", "bool", "refto(num)", "(num * num -> bool)".
(define tipo->texto
  (lambda (t)
    (cases tipo t
      (num-tipo () "num")
      (bool-tipo () "bool")
      (ref-tipo (tipo-interno)
       (string-append "refto("(tipo->texto tipo-interno)")"))
      (proc-tipo (argumentos resultado)
       (string-append
        "("
         (letrec ((convertir-tipos
                   (lambda (lista)
                     (cond
                       [(null? lista) ""]
                       [(null? (cdr lista))
                        (tipo->texto (car lista))]
                       [else
                        (string-append
                         (tipo->texto (car lista)) " * "
                         (convertir-tipos (cdr lista)))]))))
           (convertir-tipos argumentos)) " -> " (tipo->texto resultado)
         ")")))))

;; tipos-iguales? : tipo x tipo -> boolean
;; Compara dos tipos por estructura, no por identidad.
(define tipos-iguales?
  (lambda (t1 t2)
    (cases tipo t1
      (num-tipo ()
        (cases tipo t2
          (num-tipo () #t)
          (else #f)))

      (bool-tipo ()
        (cases tipo t2
          (bool-tipo () #t)
          (else #f)))

      (ref-tipo (tipo1)
        (cases tipo t2
          (ref-tipo (tipo2)
            (tipos-iguales? tipo1 tipo2))
          (else #f)))

      (proc-tipo (args1 res1)
        (cases tipo t2
          (proc-tipo (args2 res2)
            (and
             (= (length args1) (length args2))
             (tipos-listas-iguales? args1 args2)
             (tipos-iguales? res1 res2)))
          (else #f))))))

;; Funcion Auxiliar 
;; tipos-listas-iguales? : lista de tipos x lista de tipos -> boolean
;; Propósito: comparar dos listas de tipos elemento por elemento
;; para determinar si tienen la misma estructura y longitud.
(define tipos-listas-iguales?
  (lambda (lista1 lista2)
    (cond
      [(null? lista1) (null? lista2)]
      [(null? lista2) #f]
      [else
       (and
        (tipos-iguales? (car lista1) (car lista2))
        (tipos-listas-iguales? (cdr lista1) (cdr lista2)))])))

;; apply-tenv : tenv x symbol -> tipo
;; Busca el tipo del identificador. Si no está declarado levanta
;; eopl:error con «Variable no declarada: <x>».
(define apply-tenv
  (lambda (amb id)
    (cases tenv amb
      (tenv-vacio ()
        (eopl:error 'apply-tenv "Variable no declarada: ~a" id))

      (tenv-extendido (ids tipos env)
        (let ((pos (posicion-de-tipo id ids)))
          (if (number? pos)
              (list-ref tipos pos)
              (apply-tenv env id))))

      (tenv-recursivo (proc-names proc-tipos env)
        (let ((pos (posicion-de-tipo id proc-names)))
          (if (number? pos)
              (list-ref proc-tipos pos)
              (apply-tenv env id)))))))

;;Funcion Auxiliar
;; posicion-de-tipo : symbol x lista de symbol -> entero o #f
;; Propósito: buscar la posición de un identificador dentro de una
;; lista y retornar #f si no se encuentra.
(define posicion-de-tipo
  (lambda (id ids)
    (letrec ((buscar
              (lambda (lista posicion)
                (cond
                  [(null? lista) #f]
                  [(eqv? (car lista) id) posicion]
                  [else
                   (buscar (cdr lista) (+ posicion 1))]))))
      (buscar ids 0))))

;; tenv-inicial : -> tenv
;; Declara como num las cinco variables del ambiente inicial.
(define tenv-inicial
  (lambda ()
    (tenv-extendido
     '(n m p q r)
     (list
      (num-tipo)
      (num-tipo)
      (num-tipo)
      (num-tipo)
      (num-tipo))
     (tenv-vacio))))

;; tipo-de-primitiva : primitiva x lista de tipos -> tipo
;; Lo que cada primitiva exige de sus argumentos y lo que retorna: las
;; aritméticas retornan num; las relacionales, las booleanas y entre
;; retornan bool.
;; Propósito: verificar los tipos y cantidades de argumentos de cada
;; primitiva y retornar el tipo de resultado correspondiente.
(define tipo-de-primitiva
  (lambda (prim tipos)
    (cases primitiva prim
      ;; Primitivas aritmeticas
      (sum-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (minus-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (mult-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (div-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (add-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 1 1)
        (num-tipo))

      (sub-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 1 1)
        (num-tipo))

      (abs-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 1 1)
        (num-tipo))

      (mcd-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (mcm-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 #f)
        (num-tipo))

      (promedio-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 1 #f)
        (num-tipo))
      ;; Primitivas relacionales
      (mayor-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 2)
        (bool-tipo))

      (mayorigual-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 2)
        (bool-tipo))

      (menor-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 2)
        (bool-tipo))

      (menorigual-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 2)
        (bool-tipo))

      (igual-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 2 2)
        (bool-tipo))
      ;; Primitivas booleanas
      (not-prim ()
        (verificar-argumentos-primitiva tipos (bool-tipo) 1 1)
        (bool-tipo))

      (and-prim ()
        (verificar-argumentos-primitiva tipos (bool-tipo) 2 2)
        (bool-tipo))

      (or-prim ()
        (verificar-argumentos-primitiva tipos (bool-tipo) 2 2)
        (bool-tipo))

      (xor-prim ()
        (verificar-argumentos-primitiva tipos (bool-tipo) 2 2)
        (bool-tipo))

      (implica-prim ()
        (verificar-argumentos-primitiva tipos (bool-tipo) 2 2)
        (bool-tipo))
      ;; Primitiva entre
      (entre-prim ()
        (verificar-argumentos-primitiva tipos (num-tipo) 3 3)
        (bool-tipo)))))

;; Funcion Auxiliar
;; verificar-argumentos-primitiva :
;; lista de tipos x tipo x numero x numero -> boolean
;; Propósito: comprobar que los argumentos tengan el tipo esperado
;; y que su cantidad esté dentro del rango permitido.

(define verificar-argumentos-primitiva
  (lambda (tipos tipo-esperado minimo maximo)
    (if (or
         (< (length tipos) minimo)
         (and maximo (> (length tipos) maximo)))
        (eopl:error 'tipo-de-primitiva "Cantidad incorrecta de argumentos")
        (letrec
            ((verificar-lista
              (lambda (lista)
                (cond
                  [(null? lista) #t]
                  [(tipos-iguales? (car lista) tipo-esperado)
                   (verificar-lista (cdr lista))]
                  [else
                   (eopl:error 'tipo-de-primitiva "Tipo de argumento incorrecto: se esperaba ~a y se encontro ~a"
                    (tipo->texto tipo-esperado)
                    (tipo->texto (car lista)))]))))
          (verificar-lista tipos)))))


(provide (all-defined-out))