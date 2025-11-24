module bcd (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        iniciar,
    input  logic [15:0] binario,
    output logic [19:0] bcd_salida,
    output logic        terminado
);
    logic [35:0] registro;
    logic [4:0]  contador;
    logic        ocupado;

    always_ff @(posedge clk) begin
        logic [35:0] temp;

        if (!rst_n) begin
            terminado <= 0; ocupado <= 0; contador <= 0; registro <= 0; bcd_salida <= 0;
        end else begin
            if (iniciar && !ocupado) begin
                registro <= {20'd0, binario};
                contador <= 0;
                ocupado  <= 1;
                terminado <= 0;
            end else if (ocupado) begin
                if (contador == 16) begin
                    bcd_salida <= registro[35:16];
                    terminado  <= 1;
                    ocupado    <= 0;
                end else begin
                    // Double Dabble
                    temp = registro;
                    if (temp[19:16] >= 5) temp[19:16] += 3;
                    if (temp[23:20] >= 5) temp[23:20] += 3;
                    if (temp[27:24] >= 5) temp[27:24] += 3;
                    if (temp[31:28] >= 5) temp[31:28] += 3;
                    if (temp[35:32] >= 5) temp[35:32] += 3;

                    registro <= temp << 1;
                    contador <= contador + 1;
                end
            end
        end
    end
endmodule