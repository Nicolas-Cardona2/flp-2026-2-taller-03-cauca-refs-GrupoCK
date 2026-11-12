#lang eopl
;Autores: Nicolás Cardona García 2477349

#|
  Taller 3 — Cauca con referencias y tipos.
  Evaluación y punto de entrada.

  evaluar-expresion recorre el árbol con cases y apply-procedure liga
  los parámetros de una clausura antes de evaluar su cuerpo. Las dos se
  llaman mutuamente, así que comparten módulo, y con ellas la copia por
  valor de los argumentos, que describe cómo entra un valor a apply y no
  cómo está hecha la clausura.

  El evaluador ignora las anotaciones de tipo: las lee el parser, quedan
  en el árbol y solo las usa el chequeador.

  Las cláusulas de newref-exp, deref-exp, setref-exp, swap-exp y
  begin-exp van en evaluar-expresion, junto a las demás variantes.
  Las tres que verifican con referencia? antes de tocar el almacén son
  deref-exp, setref-exp y swap-exp; si el valor no es una referencia,
  levantan eopl:error.

  Todas las listas de expresiones se evalúan de izquierda a derecha, que
  es lo que hace observable el orden cuando hay efectos sobre el almacén.
|#

(require "sintaxis.rkt")
(require "almacen.rkt")
(require "ambiente.rkt")
(require "primitivas.rkt")

;; copia-por-valor : valor -> valor
;; El paso por valor entrega una copia del argumento. para un numero, un
;; booleano o un procedimiento la copia es el mismo valor, para una referencia es una celda nueva con el mismo contenido, applyref no usa esta funcion ahi el parámetro queda ligado a la misma celda
(define copia-por-valor
  (lambda (val)
    (if (referencia? val)
        (newref! (deref val))
        val)))

;; copiar-valores : lista de valores -> lista de valores
;; Aplica copia-por-valor a cada elemento, de izquierda a derecha, para que las celdas nuevas queden reservadas en el orden de los argumentos
(define copiar-valores
  (lambda (vals)
    (if (null? vals)
        '()
        (let ((primero (copia-por-valor (car vals))))
          (cons primero (copiar-valores (cdr vals)))))))

;; evaluar-lista : lista de expresion x ambiente -> lista de valores
;; evalua las expresiones de izquierda a derecha y retorna sus valores en el mismo orden
(define evaluar-lista
  (lambda (exps env)
    (if (null? exps)
        '()
        (let ((primero (evaluar-expresion (car exps) env)))
          (cons primero (evaluar-lista (cdr exps) env))))))

;; buscar-referencias : lista de symbol x ambiente -> lista de referencias
;; Busca cada identificador en el ambiente y verifica que su valor sea una referencia, si alguno no lo es, levanta eopl:error
(define buscar-referencias
  (lambda (ids env)
    (if (null? ids)
        '()
        (let ((val (apply-env env (car ids))))
          (if (referencia? val)
              (cons val (buscar-referencias (cdr ids) env))
              (eopl:error 'applyref
                          "El paso por referencia exige variables ligadas a referencias: ~s no lo esta"
                          (car ids)))))))

;; evaluar-secuencia : valor x lista de expresion x ambiente -> valor
;; Evalúa las expresiones restantes de izquierda a derecha y retorna el valor de la ultima, si no quedan, retorna el valor ya calculado
(define evaluar-secuencia
  (lambda (ultimo exps env)
    (if (null? exps)
        ultimo
        (evaluar-secuencia (evaluar-expresion (car exps) env) (cdr exps) env))))

;; elegir-rama : numero x lista de numero x lista de expresion x expresion x ambiente -> valor
;; Evalúa la expresion asociada al primer numero igual a val, si ninguno coincide, evalua la expresion por defecto
(define elegir-rama
  (lambda (val nums exps defecto env)
    (cond
      ((null? nums) (evaluar-expresion defecto env))
      ((= val (car nums)) (evaluar-expresion (car exps) env))
      (else (elegir-rama val (cdr nums) (cdr exps) defecto env)))))

;; apply-procedure : procval x lista de valores -> valor
;; Verifica la aridad y evalua el cuerpo en el ambiente de la clausura extendido con los parametros
(define apply-procedure
  (lambda (proc args)
    (cases procval proc
      (cerradura (ids body env)
        (if (= (length ids) (length args))
            (evaluar-expresion body (ambiente-extendido ids args env))
            (eopl:error 'apply-procedure
                        "El procedimiento espera ~s argumentos y recibio ~s"
                        (length ids) (length args)))))))

;; evaluar-expresion : expresion x ambiente -> valor
;; Una cláusula por variante de la gramatica, la condicion de un if se verifica con boolean? antes de ramificar
(define evaluar-expresion
  (lambda (exp env)
    (cases expresion exp
      (lit-exp (n) n)
      (var-exp (id) (apply-env env id))
      (true-exp () #t)
      (false-exp () #f)

      (prim-exp (prim rands)
        (evaluar-primitiva prim (evaluar-lista rands env)))

      (if-exp (condicion verdadera falsa)
        (let ((c (evaluar-expresion condicion env)))
          (if (boolean? c)
              (if c
                  (evaluar-expresion verdadera env)
                  (evaluar-expresion falsa env))
              (eopl:error 'if "La condicion del if debe ser booleana: ~s" c))))

      ;; let liga sin copiar, let otro = celda comparte la celda (alias)
      (let-exp (ids rands cuerpo)
        (evaluar-expresion cuerpo
                           (ambiente-extendido ids (evaluar-lista rands env) env)))

      ;; las anotaciones de tipo (segundo campo) se ignoran
      (proc-exp (ids tipos cuerpo)
        (cerradura ids cuerpo env))

      ;; apply paso por valor, las referencias se copian a celdas nuevas
      (app-exp (rator rands)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure proc (copiar-valores (evaluar-lista rands env)))
              (eopl:error 'apply "Se intento aplicar algo que no es un procedimiento: ~s" proc))))

      (letrec-exp (tipos-res nombres idss tipos-args cuerpos cuerpo)
        (evaluar-expresion cuerpo
                           (ambiente-recursivo nombres idss cuerpos env)))

      (case-exp (e n1 e1 nums exps defecto)
        (let ((val (evaluar-expresion e env)))
          (if (number? val)
              (elegir-rama val (cons n1 nums) (cons e1 exps) defecto env)
              (eopl:error 'case "La expresion del case debe ser un numero: ~s" val))))

      (newref-exp (e)
        (newref! (evaluar-expresion e env)))

      (deref-exp (e)
        (let ((ref (evaluar-expresion e env)))
          (if (referencia? ref)
              (deref ref)
              (eopl:error 'deref "deref espera una referencia: ~s" ref))))

      ;; setref evalua la referencia y luego el valor, retorna 1
      (setref-exp (e1 e2)
        (let* ((ref (evaluar-expresion e1 env))
               (val (evaluar-expresion e2 env)))
          (if (referencia? ref)
              (begin (setref! ref val) 1)
              (eopl:error 'setref "setref espera una referencia: ~s" ref))))

      ;; swap: guarda los dos contenidos antes de escribir, de modo que ninguno se pierde ni siquiera cuando las dos referencias son la misma retorna el contenido anterior de la segunda celda
      (swap-exp (e1 e2)
        (let* ((ref1 (evaluar-expresion e1 env))
               (ref2 (evaluar-expresion e2 env)))
          (if (and (referencia? ref1) (referencia? ref2))
              (let ((v1 (deref ref1))
                    (v2 (deref ref2)))
                (setref! ref1 v2)
                (setref! ref2 v1)
                v2)
              (eopl:error 'swap "swap espera dos referencias: ~s y ~s" ref1 ref2))))

      (begin-exp (primera resto)
        (evaluar-secuencia (evaluar-expresion primera env) resto env))

      ;; applyref: paso por referencia los parametros quedan ligados a las mismas referencias, sin copiarlas
      (app-ref-exp (rator ids)
        (let ((proc (evaluar-expresion rator env)))
          (if (procval? proc)
              (apply-procedure proc (buscar-referencias ids env))
              (eopl:error 'applyref "Se intento aplicar algo que no es un procedimiento: ~s" proc)))))))

;; evaluar-programa : programa -> valor deja el almacen vacío y evalua el cuerpo en el ambiente inicial
(define evaluar-programa
  (lambda (pgm)
    (cases programa pgm
      (a-program (cuerpo)
        (initialize-store!)
        (evaluar-expresion cuerpo (ambiente-inicial))))))

;; interpretar : string -> valor analiza el texto con el parser y lo evalua
(define interpretar
  (lambda (texto)
    (evaluar-programa (parser texto))))

;; interpretador : -> void el ciclo de lectura, con sllgen:make-rep-loop sobre evaluar-programa
(define interpretador
  (lambda ()
    (sllgen:make-rep-loop "Cauca-refs> "
                          evaluar-programa
                          (sllgen:make-stream-parser
                           especificacion-lexica
                           especificacion-gramatical))))

(provide (all-defined-out))