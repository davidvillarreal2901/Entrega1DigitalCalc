`timescale 1ns/1ps

module divisor_TB;
    logic clk, rst_n, iniciar, terminado;
    logic [15:0] dividendo, divisor_in;
    logic [31:0] cociente;

    // Instanciamos el módulo 'divisor' con sus puertos
    divisor uut (
        .clk(clk), .rst_n(rst_n), .iniciar(iniciar),
        .dividendo(dividendo), .divisor(divisor_in),
        .cociente(cociente), .terminado(terminado)
    );

    always #20 clk = ~clk;

    initial begin
        $dumpfile("build/divisor.vcd");
        $dumpvars(0, divisor_TB);

        clk = 0; rst_n = 0; iniciar = 0;
        #100 rst_n = 1;

        // Prueba 1: 42 / 3
        #40 dividendo = 42; divisor_in = 3; iniciar = 1;
        #40 iniciar = 0;
        wait(terminado);
        #20;
        if (cociente == 14) $display("Division 42/3 PASÓ: %d", cociente);
        else $error("FALLÓ 42/3. Obtenido: %d", cociente);

        // Prueba 2: 0 / 12
        #100 dividendo = 0; divisor_in = 12; iniciar = 1;
        #40 iniciar = 0;
        wait(terminado);
        #20;
        if (cociente == 0) $display("Division 0/12 PASÓ: %d", cociente);

        $finish;
    end
endmodule