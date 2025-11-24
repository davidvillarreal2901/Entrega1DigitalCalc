`timescale 1ns/1ps

module bcd_TB;
    logic clk, rst_n, iniciar, terminado;
    logic [15:0] binario;
    logic [19:0] bcd_salida;

    // Instanciamos el módulo 'bcd'
    bcd uut (
        .clk(clk), .rst_n(rst_n), .iniciar(iniciar),
        .binario(binario), .bcd_salida(bcd_salida), .terminado(terminado)
    );

    always #20 clk = ~clk;

    initial begin
        $dumpfile("build/bcd.vcd");
        $dumpvars(0, bcd_TB);

        clk = 0; rst_n = 0; iniciar = 0;
        #100 rst_n = 1;

        // Prueba 1: 255
        #40 binario = 255; iniciar = 1;
        #40 iniciar = 0;
        wait(terminado);
        #20;
        // 255 -> 0x00255 en BCD
        if (bcd_salida[11:0] == 12'h255) $display("BCD(255) PASÓ: %x", bcd_salida);
        else $error("FALLÓ BCD(255). Obtenido: %x", bcd_salida);

        $finish;
    end
endmodule