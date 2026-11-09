#lang eopl
#|
;Autores:
Nicolás Cardona García 2477349,
Laura Sofía Echeverry González 2477067,
Santiago Serrano Morales 2477006,
Samuel Esteban Peña Jaramillo 2477399.
|#

#|
  Taller 3 — Cauca con referencias y tipos.
  Especificación léxica y gramatical.

  Aquí van los tokens, las producciones con las anotaciones de tipo, los
  datatypes que SLLGEN genera a partir de ellas (programa, expresion,
  tipo, primitiva), el scanner y el parser.

  El módulo no requiere ningún otro: lo requieren los cinco del
  intérprete y los dos del chequeador, de modo que la gramática se
  escribe una sola vez y los dos lados recorren el mismo árbol.

  la gramática completa conserva la del taller 2 e incorpora los
  dos cambios de la sección «especificación de cauca con
  referencias y tipos» del enunciado. ✮⋆ ̇
|#

;;; ==========================================================
;;; 1. Especificación léxica
;;; ==========================================================
;; Los comentarios de línea, los identificadores y los números.

#|
  se conservan los enteros y decimales del taller 2,
  incluidos los negativos.
|#

(define especificacion-lexica
  '((white-sp (whitespace) skip)
    (comentario ("//" (arbno (not #\newline))) skip)
    (identificador (letter (arbno (or letter digit "_" "?"))) symbol)
    (numero (digit (arbno digit)) number)
    (numero ("-" digit (arbno digit)) number)
    (numero (digit (arbno digit) "." digit (arbno digit)) number)
    (numero ("-" digit (arbno digit) "." digit (arbno digit)) number)))

;;; ==========================================================
;;; 2. Especificación gramatical
;;; ==========================================================
;; Cuatro no terminales: programa, expresion, tipo y primitiva.

#|
  se completan, con los nombres de constructor que fija el enunciado:
    - las expresiones del taller 2: var-exp, true-exp, false-exp,
      if-exp, let-exp, proc-exp, app-exp, letrec-exp, case-exp
    - las de la parte 1: newref-exp, deref-exp, setref-exp, swap-exp,
      begin-exp
    - la de la parte 2: app-ref-exp
    - los tipos: num-tipo, bool-tipo, ref-tipo, proc-tipo
    - las primitivas del taller 2
|#

;; proc-exp y letrec-exp llevan las anotaciones de tipo. el tipo que
;; antecede al nombre en letrec es el del resultado del procedimiento.

(define especificacion-gramatical
  '((programa (expresion) a-program)

    #| expresiones básicas del taller 2. |#

    (expresion (numero) lit-exp)
    (expresion (identificador) var-exp)
    (expresion ("true") true-exp)
    (expresion ("false") false-exp)

    (expresion
     (primitiva "(" (separated-list expresion ",") ")")
     prim-exp)

    (expresion
     ("if" expresion "then" expresion "else" expresion "end")
     if-exp)

    (expresion
     ("let" (arbno identificador "=" expresion) "in" expresion "end")
     let-exp)

    #|
      procedimientos con parámetros anotados.
      proc-exp recibe identificadores, tipos y cuerpo.
    |#

    (expresion
     ("proc" "(" (separated-list identificador ":" tipo ",") ")"
      expresion "end")
     proc-exp)

    (expresion
     ("apply" expresion "(" (separated-list expresion ",") ")")
     app-exp)

    #|
      letrec-exp recibe, en este orden:
      tipos de resultado, nombres, listas de parámetros,
      listas de tipos de parámetros, cuerpos y cuerpo principal.
    |#

    (expresion
     ("letrec"
      (arbno tipo identificador
             "(" (separated-list identificador ":" tipo ",") ")"
             "=" expresion)
      "in" expresion "end")
     letrec-exp)

    (expresion
     ("case" expresion
      "of" numero "=>" expresion
      (arbno "of" numero "=>" expresion)
      "otherwise" "=>" expresion "end")
     case-exp)

    #| referencias y secuencias. ✮⋆ ̇ |#

    (expresion
     ("newref" "(" expresion ")")
     newref-exp)

    (expresion
     ("deref" "(" expresion ")")
     deref-exp)

    (expresion
     ("setref" "(" expresion "," expresion ")")
     setref-exp)

    (expresion
     ("swap" "(" expresion "," expresion ")")
     swap-exp)

    #|
      begin-exp conserva la primera expresión por separado
      y las restantes en una lista.
    |#

    (expresion
     ("begin" expresion (arbno ";" expresion) "end")
     begin-exp)

    #|
      applyref recibe identificadores, no expresiones arbitrarias.
      comprobar que estén ligados a referencias corresponde
      al intérprete y al chequeador.
    |#

    (expresion
     ("applyref" expresion "(" (separated-list identificador ",") ")")
     app-ref-exp)

    #| tipos compartidos por el intérprete y el chequeador. |#

    (tipo ("num") num-tipo)
    (tipo ("bool") bool-tipo)

    (tipo
     ("refto" "(" tipo ")")
     ref-tipo)

    (tipo
     ("(" (separated-list tipo "*") "->" tipo ")")
     proc-tipo)

    #| primitivas del taller 2, con sus constructores originales. |#

    (primitiva ("+") sum-prim)
    (primitiva ("-") minus-prim)
    (primitiva ("*") mult-prim)
    (primitiva ("/") div-prim)
    (primitiva ("add1") add-prim)
    (primitiva ("sub1") sub-prim)
    (primitiva (">") mayor-prim)
    (primitiva (">=") mayorigual-prim)
    (primitiva ("<") menor-prim)
    (primitiva ("<=") menorigual-prim)
    (primitiva ("==") igual-prim)
    (primitiva ("not") not-prim)
    (primitiva ("and") and-prim)
    (primitiva ("or") or-prim)
    (primitiva ("abs") abs-prim)
    (primitiva ("mcd") mcd-prim)
    (primitiva ("mcm") mcm-prim)
    (primitiva ("promedio") promedio-prim)
    (primitiva ("xor") xor-prim)
    (primitiva ("implica") implica-prim)
    (primitiva ("entre") entre-prim)))

;;; ==========================================================
;;; 3. Datatypes, scanner y parser
;;; ==========================================================

(sllgen:make-define-datatypes especificacion-lexica especificacion-gramatical)

#|
  mostrar-datatypes : () -> lista
  propósito: retornar los define-datatype generados por la gramática
  para revisar los constructores y el orden de sus campos.
|#

(define mostrar-datatypes
  (lambda () (sllgen:list-define-datatypes especificacion-lexica especificacion-gramatical)))

;; scanner : string -> lista de tokens
#|
  propósito: convertir el texto de entrada en tokens,
  omitiendo espacios y comentarios.
|#

(define scanner
  (lambda (texto)
    ((sllgen:make-string-scanner
      especificacion-lexica especificacion-gramatical)
     texto)))

;; parser : string -> programa
#|
  propósito: convertir el texto de un programa en su árbol
  de sintaxis abstracta, conservando las anotaciones de tipo.
|#

(define parser
  (lambda (texto)
    ((sllgen:make-string-parser
      especificacion-lexica especificacion-gramatical)
     texto)))

(provide (all-defined-out))