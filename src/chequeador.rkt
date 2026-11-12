#lang eopl
#|
Autores:
Santiago Serrano Morales 2477006
|#

#|
  Taller 3 — Cauca con referencias y tipos.
  Reglas de tipado y chequeo del programa (Parte 3).

  type-of recorre el árbol con cases sobre un ambiente de tipos y no
  evalúa nada: una regla por variante de expresión, tal como están
  escritas en el cuadro del enunciado.

  Los mensajes de error se distinguen uno de otro. Son los nueve del
  cuadro «Mensajes de error», con ese texto.

  El módulo requiere sintaxis.rkt y tipos.rkt, y ningún otro módulo del
  intérprete: el árbol que recorre es el que produjo el parser, con las
  anotaciones de tipo adentro.
|#

(require "sintaxis.rkt")
(require "tipos.rkt")

;; ==========================================================
;; 1. Funciones auxiliares del chequeador
;; ==========================================================

;; ultimo-elemento : lista -> elemento
;; Propósito: obtener el último elemento de una lista no vacía.
(define ultimo-elemento
  (lambda (lista)
    (if (null? (cdr lista))
        (car lista)
        (ultimo-elemento (cdr lista)))))

;; verificar-tipos-argumentos :
;; lista de tipos x lista de tipos x entero -> boolean
;; Propósito: comparar los tipos reales de los argumentos con
;; los tipos declarados por un procedimiento.
(define verificar-tipos-argumentos
  (lambda (esperados reales posicion)
    (cond
      ((null? esperados) #t)
      ((tipos-iguales? (car esperados) (car reales))
       (verificar-tipos-argumentos
        (cdr esperados)
        (cdr reales)
        (+ posicion 1)))
      (else
       (eopl:error 'type-of
         "El argumento ~s debe ser ~s, se encontro ~s"
         posicion
         (tipo->texto (car esperados))
         (tipo->texto (car reales)))))))

;; verificar-tipos-ramas : tipo x lista de tipos -> tipo
;; Propósito: comprobar que todas las ramas de una expresión
;; case tengan el mismo tipo.
(define verificar-tipos-ramas
  (lambda (tipo-esperado tipos)
    (cond
      ((null? tipos) tipo-esperado)
      ((tipos-iguales? tipo-esperado (car tipos))
       (verificar-tipos-ramas
        tipo-esperado
        (cdr tipos)))
      (else
       (eopl:error 'type-of
         "Las ramas del case deben coincidir: ~s vs ~s"
         (tipo->texto tipo-esperado)
         (tipo->texto (car tipos)))))))

;; verificar-cuerpos-letrec :
;; listas de nombres, tipos, parametros y cuerpos x ambiente
;; Propósito: verificar que cada cuerpo de letrec tenga el
;; tipo de resultado declarado para su procedimiento.
(define verificar-cuerpos-letrec
  (lambda (nombres tipos-res idss tipos-args cuerpos amb)
    (if (null? nombres)
        #t
        (let ((tipo-cuerpo
               (type-of
                (car cuerpos)
                (tenv-extendido
                 (car idss)
                 (car tipos-args)
                 amb))))
          (if (tipos-iguales? tipo-cuerpo (car tipos-res))
              (verificar-cuerpos-letrec
               (cdr nombres)
               (cdr tipos-res)
               (cdr idss)
               (cdr tipos-args)
               (cdr cuerpos)
               amb)
              (eopl:error 'type-of
                "El procedimiento ~s declara ~s y su cuerpo da ~s"
                (car nombres)
                (tipo->texto (car tipos-res))
                (tipo->texto tipo-cuerpo)))))))

;; verificar-argumentos-referencia :
;; lista de tipos x lista de identificadores x ambiente x entero
;; Propósito: comprobar que cada argumento de applyref sea una
;; variable declarada con un tipo de referencia compatible.
(define verificar-argumentos-referencia
  (lambda (esperados ids amb posicion)
    (cond
      ((null? esperados) #t)
      (else
       (let ((tipo-real (apply-tenv amb (car ids))))
         (cases tipo (car esperados)
           (ref-tipo (tipo-interno)
             (if (tipos-iguales? (car esperados) tipo-real)
                 (verificar-argumentos-referencia
                  (cdr esperados)
                  (cdr ids)
                  amb
                  (+ posicion 1))
                 (eopl:error 'type-of
                   "El argumento ~s debe ser ~s, se encontro ~s"
                   posicion
                   (tipo->texto (car esperados))
                   (tipo->texto tipo-real)))
           )
           (num-tipo ()
             (eopl:error 'type-of
               "El parametro ~s de applyref debe ser refto(t), se encontro ~s"
               posicion
               (tipo->texto (car esperados))))
           (bool-tipo ()
             (eopl:error 'type-of
               "El parametro ~s de applyref debe ser refto(t), se encontro ~s"
               posicion
               (tipo->texto (car esperados))))
           (proc-tipo (argumentos resultado)
             (eopl:error 'type-of
               "El parametro ~s de applyref debe ser refto(t), se encontro ~s"
               posicion
               (tipo->texto (car esperados))))))))))

;; ==========================================================
;; 2. Chequeador de expresiones
;; ==========================================================

;; type-of : expresion x tenv -> tipo
;; El tipo de la expresión bajo el ambiente de tipos, o eopl:error con
;; el mensaje que explique el conflicto.
;; Propósito: determinar el tipo de una expresión bajo un ambiente
;; de tipos, verificando las reglas de tipado de Cauca.
(define type-of
  (lambda (exp amb)
    (cases expresion exp
      (lit-exp (num)
        (num-tipo))

      (true-exp ()
        (bool-tipo))

      (false-exp ()
        (bool-tipo))

      (var-exp (id)
        (apply-tenv amb id))

      (prim-exp (prim exps)
        (tipo-de-primitiva
         prim
         (map
          (lambda (exp)
            (type-of exp amb))
          exps)))

      (if-exp (exp1 exp2 exp3)
        (let ((tipo-condicion (type-of exp1 amb))
              (tipo-then (type-of exp2 amb))
              (tipo-else (type-of exp3 amb)))
          (if (not (tipos-iguales?
                    tipo-condicion
                    (bool-tipo)))
              (eopl:error 'type-of
                "La condicion del if debe ser bool, se encontro ~s"
                (tipo->texto tipo-condicion))
              (if (tipos-iguales? tipo-then tipo-else)
                  tipo-then
                  (eopl:error 'type-of
                    "Las ramas del if deben coincidir: ~s vs ~s"
                    (tipo->texto tipo-then)
                    (tipo->texto tipo-else))))))

      (let-exp (ids exps body)
        (let ((tipos
               (map
                (lambda (exp)
                  (type-of exp amb))
                exps)))
          (type-of
           body
           (tenv-extendido ids tipos amb))))

      (proc-exp (ids tipos body)
        (let ((tipo-cuerpo
               (type-of
                body
                (tenv-extendido ids tipos amb))))
          (proc-tipo tipos tipo-cuerpo)))

      (app-exp (rator rands)
        (let ((tipo-operador (type-of rator amb)))
          (cases tipo tipo-operador
            (proc-tipo (tipos-args tipo-resultado)
              (if (= (length tipos-args) (length rands))
                  (let ((tipos-reales
                         (map
                          (lambda (exp)
                            (type-of exp amb))
                          rands)))
                    (verificar-tipos-argumentos
                     tipos-args tipos-reales 1)
                    tipo-resultado)
                  (eopl:error 'type-of
                    "El procedimiento espera ~s argumentos y recibio ~s"
                    (length tipos-args)
                    (length rands))))

            (num-tipo ()
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador)))

            (bool-tipo ()
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador)))

            (ref-tipo (tipo-interno)
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador))))))

      (letrec-exp (tipos-res proc-names idss tipos-args bodies body)
        (let ((tipos-proc
               (map
                (lambda (argumentos resultado)
                  (proc-tipo argumentos resultado))
                tipos-args
                tipos-res)))
          (let ((amb-recursivo
                 (tenv-recursivo
                  proc-names
                  tipos-proc
                  amb)))
            (verificar-cuerpos-letrec
             proc-names
             tipos-res
             idss
             tipos-args
             bodies
             amb-recursivo)
            (type-of body amb-recursivo))))

      (case-exp (exp numero rama-primera numeros-adicionales ramas-adicionales otherwise)
        (let ((tipo-exp (type-of exp amb)))
          (if (not (tipos-iguales? tipo-exp (num-tipo)))
              (eopl:error 'type-of
                "La expresion del case debe ser num, se encontro ~s"
                (tipo->texto tipo-exp))
              (let ((tipo-primera
                     (type-of rama-primera amb))
                    (tipos-adicionales
                     (map
                      (lambda (rama)
                        (type-of rama amb))
                      ramas-adicionales))
                    (tipo-otherwise
                     (type-of otherwise amb)))
                (verificar-tipos-ramas
                 tipo-primera
                 (append tipos-adicionales
                         (list tipo-otherwise)))))))

      (newref-exp (exp)
        (ref-tipo (type-of exp amb)))

      (deref-exp (exp)
        (let ((tipo-exp (type-of exp amb)))
          (cases tipo tipo-exp
            (ref-tipo (tipo-interno)
              tipo-interno)
            (num-tipo ()
              (eopl:error 'type-of
                "deref espera refto(t), se encontro ~s"
                (tipo->texto tipo-exp)))
            (bool-tipo ()
              (eopl:error 'type-of
                "deref espera refto(t), se encontro ~s"
                (tipo->texto tipo-exp)))
            (proc-tipo (argumentos resultado)
              (eopl:error 'type-of
                "deref espera refto(t), se encontro ~s"
                (tipo->texto tipo-exp))))))

      (setref-exp (ref exp)
        (let ((tipo-ref (type-of ref amb))
              (tipo-valor (type-of exp amb)))
          (cases tipo tipo-ref
            (ref-tipo (tipo-interno)
              (if (tipos-iguales? tipo-interno tipo-valor)
                  (num-tipo)
                  (eopl:error 'type-of
                    "La celda guarda ~s y se intento escribir ~s"
                    (tipo->texto tipo-interno)
                    (tipo->texto tipo-valor))))
            (num-tipo ()
              (eopl:error 'type-of
                "setref espera refto(t), se encontro ~s"
                (tipo->texto tipo-ref)))
            (bool-tipo ()
              (eopl:error 'type-of
                "setref espera refto(t), se encontro ~s"
                (tipo->texto tipo-ref)))
            (proc-tipo (argumentos resultado)
              (eopl:error 'type-of
                "setref espera refto(t), se encontro ~s"
                (tipo->texto tipo-ref))))))

      (swap-exp (ref1 ref2)
        (let ((tipo-ref1 (type-of ref1 amb))
              (tipo-ref2 (type-of ref2 amb)))
          (cases tipo tipo-ref1
            (ref-tipo (tipo-interno1)
              (cases tipo tipo-ref2
                (ref-tipo (tipo-interno2)
                  (if (tipos-iguales?
                       tipo-interno1 tipo-interno2)
                      tipo-interno1
                      (eopl:error 'type-of
                        "Las referencias de swap deben guardar el mismo tipo: ~s vs ~s"
                        (tipo->texto tipo-interno1)
                        (tipo->texto tipo-interno2))))
                (num-tipo ()
                  (eopl:error 'type-of
                    "swap espera dos referencias, se encontro ~s"
                    (tipo->texto tipo-ref2)))
                (bool-tipo ()
                  (eopl:error 'type-of
                    "swap espera dos referencias, se encontro ~s"
                    (tipo->texto tipo-ref2)))
                (proc-tipo (argumentos resultado)
                  (eopl:error 'type-of
                    "swap espera dos referencias, se encontro ~s"
                    (tipo->texto tipo-ref2)))))
            (num-tipo ()
              (eopl:error 'type-of
                "swap espera dos referencias, se encontro ~s"
                (tipo->texto tipo-ref1)))
            (bool-tipo ()
              (eopl:error 'type-of
                "swap espera dos referencias, se encontro ~s"
                (tipo->texto tipo-ref1)))
            (proc-tipo (argumentos resultado)
              (eopl:error 'type-of
                "swap espera dos referencias, se encontro ~s"
                (tipo->texto tipo-ref1))))))

      (begin-exp (exp exps)
        (let ((tipos
               (map
                (lambda (expresion)
                  (type-of expresion amb))
                (cons exp exps))))
          (ultimo-elemento tipos)))

      (app-ref-exp (rator ids)
        (let ((tipo-operador (type-of rator amb)))
          (cases tipo tipo-operador

            (proc-tipo (tipos-args tipo-resultado)
              (if (= (length tipos-args) (length ids))
                  (begin
                    (verificar-argumentos-referencia
                     tipos-args ids amb 1)
                    tipo-resultado)
                  (eopl:error 'type-of
                    "El procedimiento espera ~s argumentos y recibio ~s"
                    (length tipos-args)
                    (length ids))))

            (num-tipo ()
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador)))

            (bool-tipo ()
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador)))

            (ref-tipo (tipo-interno)
              (eopl:error 'type-of
                "Se intento aplicar un valor de tipo ~s"
                (tipo->texto tipo-operador)))))))))
 


;; type-of-program : programa -> tipo
;; Chequea el programa en el ambiente de tipos inicial.
(define type-of-program
  (lambda (pgm)
    (cases programa pgm
      (a-program (exp)
        (type-of exp (tenv-inicial))))))

;; tipo-de-texto : string -> string
;; Analiza el texto, lo chequea y describe el tipo resultante.
(define tipo-de-texto
  (lambda (texto)
    (tipo->texto
     (type-of-program
      (parser texto)))))

(provide (all-defined-out))
