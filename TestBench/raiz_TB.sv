`timescale 1ns/1ps

module raiz_TB;
    logic clk, rst_n, iniciar, terminado;
    logic [15:0] radicando, raiz_res;

    // Instanciamos el módulo 'raiz'
    raiz uut (
        .clk(clk), .rst_n(rst_n), .iniciar(iniciar),
        .radicando(radicando), .raiz_res(raiz_res), .terminado(terminado)
    );

    always #20 clk = ~clk;

    initial begin
        $dumpfile("build/raiz.vcd");
        $dumpvars(0, raiz_TB);

        clk = 0; rst_n = 0; iniciar = 0;
        #100 rst_n = 1;

        // Prueba 1: sqrt(144)
        #40 radicando = 144; iniciar = 1;
        #40 iniciar = 0;
        wait(terminado);
        #20;
        if (raiz_res == 12) $display("Raiz(144) PASÓ: %d", raiz_res);
        else $error("FALLÓ Raiz(144). Obtenido: %d", raiz_res);

        // Prueba 2: sqrt(2)
        #100 radicando = 2; iniciar = 1;
        #40 iniciar = 0;
        wait(terminado);
        #20;
        if (raiz_res == 1) $display("Raiz(2) PASÓ: %d", raiz_res);

        $finish;
    end
endmodule