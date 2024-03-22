DrawMap_16x16_MapOr:
 
    ;;;;;; Impresion de la parte grafica de los tiles ;;;;;;
    ld ix, (DM_MAP)           ; IX apunta al mapa
    ld a, (DM_HEIGHT)
    ld b, a                   ; B = ALTO_EN_TILES (para bucle altura)
 
drawm16_yloop:
    push bc                   ; Guardamos el valor de B
 
    ld a, (DM_HEIGHT)         ; A = ALTO_EN_TILES
    sub b                     ; A = ALTO - iteracion_bucle = Y actual
    rlca                      ; A = Y * 2
 
    ;;; Calculamos la direccion destino en pantalla como
    ;;; DIR_PANT = DIRECCION(X_INICIAL, Y_INICIAL + Y*2)
    ld bc, (DM_COORD_X)       ; B = DB_COORD_Y y C = DB_COORD_X
    add a, b
    ld b, a
    ld a, b
    and $18
    add a, $40
    ld h, a
    ld a, b
    and 7
    rrca
    rrca
    rrca
    add a, c
    ld l, a                   ; HL = DIR_PANTALLA(X_INICIAL,Y_INICIAL+Y*2)
 
    ld a, (DM_WIDTH)
    ld b, a                   ; B = ANCHO_EN_TILES
 
drawm16_xloop:
    push bc                   ; Nos guardamos el contador del bucle
     
    ld a, (ix+0)              ; Leemos un byte del mapa
    inc ix                    ; Apuntamos al siguiente byte del mapa
 
    cp 255                    ; Bloque especial a saltar: no se dibuja
    jp z, drawm16_next
 
    ld b, a
    ex af, af'                ; Nos guardamos una copia del bloque en A'
    ld a, b
 
    ;;; Calcular posicion origen (array sprites) en HL como:
    ;;;     direccion = base_sprites + (NUM_SPRITE*32)
    ex de, hl                 ; Intercambiamos DE y HL (DE=destino)
    ld bc, (DM_SPRITES)
    ld l, 0
    srl a
    rr l
    rra
    rr l
    rra
    rr l
    ld h, a
    add hl, bc                ; HL = BC + HL = DS_SPRITES + (DS_NUMSPR * 32)
    ex de, hl                 ; Intercambiamos DE y HL (DE=origen, HL=destino)
 
    push hl                   ; Guardamos el puntero a pantalla recien calculado
    push hl
 
    ;;; Impresion de los primeros 2 bloques horizontales del tile
 
    ld b, 8
drawm16_loop1:
 
    ld a, (de)                ; Bloque 1: Leemos dato del sprite
    ld (hl), a                ; Copiamos dato a pantalla
    inc de                    ; Incrementar puntero en sprite
    inc l                     ; Incrementar puntero en pantalla
    ld a, (de)                ; Bloque 2: Leemos dato del sprite
    ld (hl), a                ; Copiamos dato a pantalla
    inc de                    ; Incrementar puntero en sprite
    inc h                     ; Hay que sumar 256 para ir al siguiente scanline
    dec l                     ; pero hay que restar el inc l que hicimos.
    djnz drawm16_loop1
    inc l                     ; Decrementar el ultimo incrementado en el bucle
 
    ; Avanzamos HL 1 scanline (codigo de incremento de HL en 1 scanline)
    ; desde el septimo scanline de la fila Y+1 al primero de la Y+2
    ld a, l
    add a, 31
    ld l, a
    jr c, drawm16_nofix_abajop
    ld a, h
    sub 8
    ld h, a
drawm16_nofix_abajop:
 
    ;;; Impresion de los segundos 2 bloques horizontales:
    ld b, 8
drawm16_loop2:
    ld a, (de)                ; Bloque 1: Leemos dato del sprite
    ld (hl), a                ; Copiamos dato a pantalla
    inc de                    ; Incrementar puntero en sprite
    inc l                     ; Incrementar puntero en pantalla
    ld a, (de)                ; Bloque 2: Leemos dato del sprite
    ld (hl), a                ; Copiamos dato a pantalla
    inc de                    ; Incrementar puntero en sprite
    inc h                     ; Hay que sumar 256 para ir al siguiente scanline
    dec l                     ; pero hay que restar el inc l que hicimos.
    djnz drawm16_loop2
 
 
    ;;; En este punto, los 16 scanlines del tile estan dibujados.
 
    ;;;;;; Impresion de la parte de atributos del tile ;;;;;;
 
    pop hl                    ; Recuperar puntero a inicio de tile
 
    ;;; Calcular posicion destino en area de atributos en DE.
    ld a, h                   ; Codigo de Get_Attr_Offset_From_Image
    rrca
    rrca
    rrca
    and 3
    or $58
    ld d, a
    ld e, l                   ; DE tiene el offset del attr de HL
 
    ld hl, (DM_ATTRIBS)
    ex af, af'                ; Recuperamos el bloque del mapa desde A'
    ld c, a
    ld b, 0
    add hl, bc
    add hl, bc
    add hl, bc
    add hl, bc                ; HL = HL+HL=(DS_NUMSPR*4) = Origen de atributo
 
    ldi
    ldi                       ; Imprimimos la primeras fila de atributos
 
    ;;; Avance diferencial a la siguiente linea de atributos
    ld a, e                   ; A = E
    add a, 30                 ; Sumamos A = A + 30 mas los 2 INCs de ldi.
    ld e, a                   ; Guardamos en E (E = E+30 + 2 por ldi=E+32)
    jr nc, drawm16_att_noinc
    inc d
drawm16_att_noinc:
    ldi
    ldi                       ; Imprimimos la segunda fila de atributos
 
    pop hl                    ; Recuperamos el puntero al inicio
 
drawm16_next:
    inc l                     ; Avanzamos al siguiente tile en pantalla
    inc l                     ; horizontalmente
 
    pop bc                    ; Recuperamos el contador para el bucle
    dec b                     ; djnz se sale de rango, hay que usar DEC+jp
    jp nz, drawm16_xloop


   ;;; NUEVO: Incrementar puntero de mapa a siguiente linea
    LD BC, ANCHO_MAPA_TILES - ANCHO_PANTALLA
    ADD IX, BC
    ;;; FIN NUEVO
 
    ;;; En este punto, hemos dibujado ANCHO tiles en pantalla (1 fila)
    pop bc
    dec b                     ; Bucle vertical
    jp nz, drawm16_yloop
 
    ret


Map_Inc_XOr:
    LD HL, (DM_MAPX)

    ;;; Comparacion 16 bits de HL y (ANCHO_MAPA-ANCHO_PANTALLA)
    LD A, H
    CP (ANCHO_MAPA_TILES - ANCHO_PANTALLA) / 256
    RET NZ
    LD A, L
    CP (ANCHO_MAPA_TILES - ANCHO_PANTALLA) % 256
    RET Z

    INC HL                     ; No eran iguales, podemos incrementar.
    LD (DM_MAPX), HL

    ; mueve al bicho
    push af
    ld a,(DS_COORD_X)
      
    INC a
    ld (DS_COORD_X), a
    pop af

    RET


