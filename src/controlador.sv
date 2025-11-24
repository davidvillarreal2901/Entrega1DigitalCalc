module controlador (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rx_pin,
    output logic       tx_pin,
    output logic [7:0] leds
);

    // Definición de Estados
    typedef enum logic [4:0] {
        REPOSO,
        LEER_A, LEER_OP, LEER_B,
        VERIFICAR_Q, VERIFICAR_R,
        CALCULAR,
        INICIO_OP,
        ESPERA_RESULTADO,
        INICIO_CONV, PAUSA_CONV, ESPERA_CONV,
        ESPERA_TX,
        ERROR_1, ERROR_2, ERROR_3,
        IMPRIMIR_DIG_4, IMPRIMIR_DIG_3, IMPRIMIR_DIG_2, IMPRIMIR_DIG_1, IMPRIMIR_DIG_0,
        SALTO_LINEA_1, SALTO_LINEA_2
    } estados_t;

    estados_t estado = REPOSO;
    estados_t estado_siguiente;

    logic [31:0] op1, op2, resultado_calc;
    logic [7:0]  codigo_op;
    logic        bandera_lectura;
    logic        ceros_visibles;

    // UART
    logic [7:0] rx_dato, tx_dato;
    logic       rx_listo, rx_ack, tx_start, tx_busy;

    uart #(.FRECUENCIA_RELOJ(25000000)) modulo_com (
        .clk(clk), .rst_n(rst_n),
        .rx_entrada(rx_pin), .tx_salida(tx_pin),
        .dato_rx(rx_dato), .rx_valido(rx_listo), .rx_leido(rx_ack),
        .dato_tx(tx_dato), .tx_inicio(tx_start), .tx_ocupado(tx_busy)
    );

    // Módulos Matemáticos
    logic [31:0] res_mult, res_div;
    logic [15:0] res_raiz;
    logic        fin_mult, fin_div, fin_raiz, fin_bcd;
    logic        start_mult, start_div, start_raiz, start_bcd;
    logic [19:0] res_bcd;

    multiplicador u_mult (.clk(clk), .rst_n(rst_n), .iniciar(start_mult), .operando_a(op1[15:0]), .operando_b(op2[15:0]), .producto(res_mult), .terminado(fin_mult));
    divisor       u_div  (.clk(clk), .rst_n(rst_n), .iniciar(start_div),  .dividendo(op1[15:0]),  .divisor(op2[15:0]),   .cociente(res_div),  .terminado(fin_div));
    raiz          u_raiz (.clk(clk), .rst_n(rst_n), .iniciar(start_raiz), .radicando(op1[15:0]), .raiz_res(res_raiz),   .terminado(fin_raiz));
    bcd           u_conv (.clk(clk), .rst_n(rst_n), .iniciar(start_bcd),  .binario(resultado_calc[15:0]), .bcd_salida(res_bcd), .terminado(fin_bcd));

    // Máquina de Estados
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            estado <= REPOSO;
            op1 <= 0; op2 <= 0; resultado_calc <= 0; codigo_op <= 0;
            tx_start <= 0; start_mult <= 0; start_div <= 0; start_raiz <= 0; start_bcd <= 0;
            rx_ack <= 0; bandera_lectura <= 0; ceros_visibles <= 0;
        end else begin
            // Reset de pulsos
            tx_start <= 0; start_mult <= 0; start_div <= 0; start_raiz <= 0; start_bcd <= 0; rx_ack <= 0;

            if (!rx_listo) bandera_lectura <= 0;

            case (estado)
                REPOSO: begin
                    op1 <= 0; op2 <= 0; estado <= LEER_A;
                end

                LEER_A: begin
                    if (rx_listo && !bandera_lectura) begin
                        bandera_lectura <= 1; rx_ack <= 1;
                        if (rx_dato >= 48 && rx_dato <= 57) begin
                            op1 <= (op1 * 10) + (rx_dato - 48);
                            tx_dato <= rx_dato; tx_start <= 1;
                        end else if (rx_dato == "+" || rx_dato == "-" || rx_dato == "*" || rx_dato == "/") begin
                            codigo_op <= rx_dato; tx_dato <= rx_dato; tx_start <= 1;
                            estado <= LEER_B;
                        end else if (rx_dato == "s") begin
                            tx_dato <= rx_dato; tx_start <= 1;
                            estado <= VERIFICAR_Q;
                        end
                    end
                end

                VERIFICAR_Q: begin
                    if (rx_listo && !bandera_lectura) begin
                        bandera_lectura <= 1; rx_ack <= 1;
                        if (rx_dato == "q") begin
                            tx_dato <= rx_dato; tx_start <= 1; estado <= VERIFICAR_R;
                        end else estado <= REPOSO;
                    end
                end

                VERIFICAR_R: begin
                    if (rx_listo && !bandera_lectura) begin
                        bandera_lectura <= 1; rx_ack <= 1;
                        if (rx_dato == "r") begin
                            tx_dato <= rx_dato; tx_start <= 1;
                            codigo_op <= "s"; estado <= CALCULAR;
                        end else estado <= REPOSO;
                    end
                end

                LEER_B: begin
                    if (rx_listo && !bandera_lectura) begin
                        bandera_lectura <= 1; rx_ack <= 1;
                        if (rx_dato >= 48 && rx_dato <= 57) begin
                            op2 <= (op2 * 10) + (rx_dato - 48);
                            tx_dato <= rx_dato; tx_start <= 1;
                        end else if (rx_dato == 13 || rx_dato == 61) begin
                            tx_dato <= 61; tx_start <= 1; estado <= CALCULAR;
                        end
                    end
                end

                CALCULAR: begin
                    if (!tx_busy) begin
                        case (codigo_op)
                            "+": begin resultado_calc <= op1 + op2; estado <= INICIO_CONV; end
                            "-": begin resultado_calc <= op1 - op2; estado <= INICIO_CONV; end
                            "*": begin start_mult <= 1; estado <= INICIO_OP; end // Vamos a INICIO_OP
                            "/": begin
                                if (op2 == 0) estado <= ERROR_1;
                                else begin start_div <= 1; estado <= INICIO_OP; end
                            end
                            "s": begin start_raiz <= 1; estado <= INICIO_OP; end
                            default: estado <= REPOSO;
                        endcase
                    end
                end

                // Estado intermedio para asegurar que el módulo baje su flag 'done'
                INICIO_OP: begin
                    estado <= ESPERA_RESULTADO;
                end

                ESPERA_RESULTADO: begin
                    case (codigo_op)
                        "*": if (fin_mult) begin resultado_calc <= res_mult; estado <= INICIO_CONV; end
                        "/": if (fin_div)  begin resultado_calc <= res_div;  estado <= INICIO_CONV; end
                        "s": if (fin_raiz) begin resultado_calc <= {16'b0, res_raiz}; estado <= INICIO_CONV; end
                    endcase
                end

                INICIO_CONV: begin start_bcd <= 1; ceros_visibles <= 0; estado <= PAUSA_CONV; end
                PAUSA_CONV:  begin start_bcd <= 0; estado <= ESPERA_CONV; end
                ESPERA_CONV: begin if (fin_bcd) estado <= IMPRIMIR_DIG_4; end

                ESPERA_TX: estado <= estado_siguiente;

                ERROR_1: if(!tx_busy) begin tx_dato <= "E"; tx_start <= 1; estado_siguiente <= ERROR_2; estado <= ESPERA_TX; end
                ERROR_2: if(!tx_busy) begin tx_dato <= "r"; tx_start <= 1; estado_siguiente <= ERROR_3; estado <= ESPERA_TX; end
                ERROR_3: if(!tx_busy) begin tx_dato <= "r"; tx_start <= 1; estado_siguiente <= SALTO_LINEA_1; estado <= ESPERA_TX; end

                // Impresión
                IMPRIMIR_DIG_4: if(!tx_busy) begin
                    if(res_bcd[19:16] > 0) begin tx_dato <= res_bcd[19:16] + 48; tx_start <= 1; ceros_visibles <= 1; estado_siguiente <= IMPRIMIR_DIG_3; estado <= ESPERA_TX; end
                    else estado <= IMPRIMIR_DIG_3;
                end
                IMPRIMIR_DIG_3: if(!tx_busy) begin
                    if(res_bcd[15:12] > 0 || ceros_visibles) begin tx_dato <= res_bcd[15:12] + 48; tx_start <= 1; ceros_visibles <= 1; estado_siguiente <= IMPRIMIR_DIG_2; estado <= ESPERA_TX; end
                    else estado <= IMPRIMIR_DIG_2;
                end
                IMPRIMIR_DIG_2: if(!tx_busy) begin
                    if(res_bcd[11:8] > 0 || ceros_visibles) begin tx_dato <= res_bcd[11:8] + 48; tx_start <= 1; ceros_visibles <= 1; estado_siguiente <= IMPRIMIR_DIG_1; estado <= ESPERA_TX; end
                    else estado <= IMPRIMIR_DIG_1;
                end
                IMPRIMIR_DIG_1: if(!tx_busy) begin
                    if(res_bcd[7:4] > 0 || ceros_visibles) begin tx_dato <= res_bcd[7:4] + 48; tx_start <= 1; ceros_visibles <= 1; estado_siguiente <= IMPRIMIR_DIG_0; estado <= ESPERA_TX; end
                    else estado <= IMPRIMIR_DIG_0;
                end
                IMPRIMIR_DIG_0: if(!tx_busy) begin
                    tx_dato <= res_bcd[3:0] + 48; tx_start <= 1; estado_siguiente <= SALTO_LINEA_1; estado <= ESPERA_TX;
                end

                SALTO_LINEA_1: if(!tx_busy) begin tx_dato <= 13; tx_start <= 1; estado_siguiente <= SALTO_LINEA_2; estado <= ESPERA_TX; end
                SALTO_LINEA_2: if(!tx_busy) begin tx_dato <= 10; tx_start <= 1; estado_siguiente <= REPOSO; estado <= ESPERA_TX; end

            endcase
        end
    end

    assign leds = ~{3'b000, estado};
endmodule