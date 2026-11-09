# Taller 3 — Cauca con referencias y tipos

Fundamentos de Interpretación y Compilación de Lenguajes de Programación
Escuela de Ingeniería de Sistemas y Computación, Universidad del Valle
Carlos Andrés Delgado Saavedra

Cauca gana memoria y disciplina: un almacén indexado por referencias, con
`newref`, `deref`, `setref`, `swap` y `begin`; el paso por referencia con
`applyref`; y un chequeador estático que recorre el árbol y rechaza los
programas mal tipados sin evaluar una sola expresión. El enunciado completo,
con la especificación, las partes y las rúbricas, está publicado en el Campus
Virtual. Este repositorio es el punto de partida del grupo.

## Integrantes

Esta tabla es lo que identifica al grupo. Sin ella, o con algún dato
incompleto, la entrega pierde el 20 %; quien no aparezca aquí no cuenta como
parte del grupo.

| Nombre completo | Código | Correo institucional |
|---|---|---|
|Nicolás Cardona García |2477349 |nicolas.cardona.garcia@correounivalle.edu.co |
|Santiago Serrano Morales |2477006 |serrano.santiago@correounivalle.edu.co |
|Laura Sofía Echeverry González |2477067 |echeverry.laura@correounivalle.edu.co |
|Samuel Esteban Peña Jaramillo |2477399 |samuel.pena@correounivalle.edu.co |

## Cómo se entrega

1. **Se trabaja sobre un fork de este repositorio.** El grupo hace fork, lo
   deja público y trabaja ahí. Una entrega que no sea fork de este
   repositorio pierde el 30 % de la nota.
2. **El enlace del fork se pega en la actividad del taller en el Campus
   Virtual.** Nada más: ni archivos, ni comprimidos, ni código por correo.
3. **Se califica el último commit anterior al lunes 23 de noviembre de 2026
   a las 17:58:59.** Lo que se suba después no se tiene en cuenta.
4. Solo archivos de texto: código `.rkt` en `src/` y en la raíz, e informes
   `.md` en `docs/`. Fórmulas en LaTeX y diagramas en Mermaid dentro del
   Markdown; no se aceptan PDF, DOCX ni imágenes.
5. Las primeras líneas de cada `.rkt` llevan los autores:
   `;Autores: Nombre1 Codigo1, Nombre2 Codigo2`.
6. El historial de commits se revisa para ver el aporte de cada integrante.
   Los cambios de puro formato o de comentarios no cuentan.

## Cómo está organizado

```
src/sintaxis.rkt              Léxico, gramática con anotaciones de tipo, scanner y parser
src/almacen.rkt               Parte 1: TAD referencia y las cuatro operaciones del almacén
src/ambiente.rkt              TAD ambiente, valor procedimiento, apply-env y ambiente inicial
src/primitivas.rkt            evaluar-primitiva y las verificaciones de cantidad y tipo
src/interprete.rkt            Partes 1 y 2: evaluar-expresion, apply-procedure, copia por valor y el REPL
src/tipos.rkt                 Parte 3: comparación de tipos, ambiente de tipos y tipos de las primitivas
src/chequeador.rkt            Parte 3: type-of, type-of-program y el punto de entrada
interprete-cauca-refs.rkt     Fachada del intérprete: reúne los cinco primeros módulos
checker-cauca.rkt             Fachada del chequeador: reúne tipos.rkt y chequeador.rkt
pruebas-cauca-refs.rkt        Pruebas con rackunit; llega escrito y las del grupo se agregan al final
docs/informe-ast.md           Parte 4: se llena la plantilla
docs/informe-correccion.md    Parte 5: se llena la plantilla
```

Las dos fachadas no llevan código propio: requieren los módulos y los
reexportan con `(provide (all-from-out ...))`. Cada módulo de `src/` exporta
lo que define con `(provide (all-defined-out))`, y ni los módulos ni las
fachadas contienen pruebas. El archivo de pruebas requiere solamente las dos
fachadas, nunca un módulo de `src/` por separado.

`src/sintaxis.rkt` lo requieren los dos lados: la gramática con las
anotaciones de tipo se escribe una sola vez y el intérprete y el chequeador
recorren el mismo árbol. Lo que trae ahora es una producción por no
terminal, lo mínimo para que todo cargue; la gramática completa la escribe el
grupo.

Las funciones llegan como huecos que levantan `eopl:error` con «Sin
implementar», y encima de cada una están su contrato y su propósito. Los
datatypes que hacen falta —`referencia`, `ambiente`, `procval` y `tenv`—
están nombrados en el comentario de cabecera de su módulo. Las plantillas de
`docs/` se llenan en el mismo archivo, reemplazando los marcadores `{{...}}`
y sin quitar las secciones.

## Cómo se corre

```bash
racket pruebas-cauca-refs.rkt
```

```racket
(require "interprete-cauca-refs.rkt")
(require "checker-cauca.rkt")
(interpretar "let c = newref(0) in begin setref(c, 9); deref(c) end end")
(tipo-de-texto "proc (a : num, b : num) +(a, b) end")
```
