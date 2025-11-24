`timescale 1ns/1ps

module multiplicador_TB;
    // Señales
    logic clk;
    logic rst_n;
    logic iniciar;
    logic [15:0] operando_a;
    logic [15:0] operando_b;
    logic [31:0] producto;
    logic terminado;

    // UUT
    multiplicador uut (
        .clk(clk),
        .rst_n(rst_n),
        .iniciar(iniciar),
        .operando_a(operando_a),
        .operando_b(operando_b),
        .producto(producto),
        .terminado(terminado)
    );

    always #20 clk = ~clk;

    initial begin
        $dumpfile("build/multiplicador.vcd");
        $dumpvars(0, multiplicador_TB);

        clk = 0; rst_n = 0; iniciar = 0; operando_a = 0; operando_b = 0;
        #100 rst_n = 1;
        #20;

        // Prueba 1: 85 * 51 (0x55 * 0x33)
        $display("--- Test 1: 85 * 51 ---");
        operando_a = 16'h0055;
        operando_b = 16'h0033;
        iniciar = 1;
        #40 iniciar = 0;

        wait(terminado);
        #20;

        if (producto == 32'h10EF) $display("PASÓ: %h", producto);
        else $error("FALLÓ. Esperado: 10EF, Obtenido: %h", producto);

        // Prueba 2: Máximos
        #100;
        $display("--- Test 2: Max * Max ---");
        operando_a = 16'hFFFF;
        operando_b = 16'hFFFF;
        iniciar = 1;
        #40 iniciar = 0;

        wait(terminado);
        #20;

        if (producto == 32'hFFFE0001) $display("PASÓ MAX");

        $finish;
    end
endmodule