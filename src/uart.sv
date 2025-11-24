module uart #(
    parameter int FRECUENCIA_RELOJ = 25000000,
    parameter int VELOCIDAD_BAUD   = 115200
) (
    input  logic       clk,
    input  logic       rst_n,    // Reset activo bajo

    // Pines Físicos
    input  logic       rx_entrada,
    output logic       tx_salida,

    // Interfaz Interna
    output logic [7:0] dato_rx,
    output logic       rx_valido,
    input  logic       rx_leido,
    input  logic [7:0] dato_tx,
    input  logic       tx_inicio,
    output logic       tx_ocupado
);

    localparam int DIVISOR = FRECUENCIA_RELOJ / VELOCIDAD_BAUD / 16;

    // Muestreo (x16)
    logic [15:0] contador_baud;
    logic        pulso_muestreo;

    assign pulso_muestreo = (contador_baud == 0);

    always_ff @(posedge clk) begin
        if (!rst_n) contador_baud <= DIVISOR - 1;
        else begin
            contador_baud <= contador_baud - 1;
            if (contador_baud == 0) contador_baud <= DIVISOR - 1;
        end
    end

    // Sincronización RX
    logic rx_sinc1, rx_sinc2;
    always_ff @(posedge clk) begin
        rx_sinc1 <= rx_entrada;
        rx_sinc2 <= rx_sinc1;
    end

    logic       rx_en_proceso;
    logic [3:0] rx_muestras;
    logic [3:0] rx_indice_bit;
    logic [7:0] rx_buffer;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_en_proceso <= 0; rx_muestras <= 0; rx_indice_bit <= 0;
            rx_valido <= 0; rx_buffer <= 0; dato_rx <= 0;
        end else begin
            if (rx_leido) rx_valido <= 0; // Limpiar flag si ya se leyó

            if (pulso_muestreo) begin
                if (!rx_en_proceso) begin
                    if (!rx_sinc2) begin // Detectar Start Bit (Bajada)
                        rx_en_proceso <= 1;
                        rx_muestras   <= 7;
                        rx_indice_bit <= 0;
                    end
                end else begin
                    rx_muestras <= rx_muestras + 1;
                    if (rx_muestras == 0) begin
                        rx_indice_bit <= rx_indice_bit + 1;

                        if (rx_indice_bit == 0) begin // Verificar Start
                            if (rx_sinc2) rx_en_proceso <= 0;
                        end else if (rx_indice_bit == 9) begin // Stop Bit
                            rx_en_proceso <= 0;
                            if (rx_sinc2) begin // Stop válido
                                dato_rx   <= rx_buffer;
                                rx_valido <= 1;
                            end
                        end else begin // Bits de datos 0-7
                            rx_buffer <= {rx_sinc2, rx_buffer[7:1]};
                        end
                    end
                end
            end
        end
    end

    // Lógica de Transmisión (TX)
    logic [3:0] tx_indice_bit;
    logic [3:0] tx_muestras;
    logic [7:0] tx_buffer;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            tx_ocupado <= 0; tx_salida <= 1; 
            tx_muestras <= 0; tx_indice_bit <= 0; tx_buffer <= 0;
        end else begin
            if (tx_inicio && !tx_ocupado) begin
                tx_buffer     <= dato_tx;
                tx_indice_bit <= 0;
                tx_muestras   <= 0;
                tx_ocupado    <= 1;
            end

            if (pulso_muestreo && tx_ocupado) begin
                tx_muestras <= tx_muestras + 1;
                if (tx_muestras == 0) begin
                    tx_indice_bit <= tx_indice_bit + 1;

                    if (tx_indice_bit == 0)      tx_salida <= 0; // Start
                    else if (tx_indice_bit == 9) tx_salida <= 1; // Stop
                    else if (tx_indice_bit == 10) begin          // Fin
                        tx_indice_bit <= 0;
                        tx_ocupado    <= 0;
                    end else begin                               // Datos
                        tx_salida <= tx_buffer[0];
                        tx_buffer <= {1'b0, tx_buffer[7:1]};
                    end
                end
            end
        end
    end
endmodule