# Calculadora FPGA en SystemVerilog - Colorlight i9

Este proyecto implementa una calculadora en binario completa sobre una FPGA **Colorlight i9** (Lattice ECP5), diseñada enteramente en **SystemVerilog** utilizando una arquitectura de Hardware Puro.

El sistema se basa en una Máquina de Estados Finitos (FSM) que orquesta módulos dedicados y gestiona la comunicación serial (UART) con una terminal de minicom en el computador host (Ojalá MacOS😎) a 115200 baudios y especificando el puerto.

Operaciones soportadas:  
    &nbsp;&nbsp;&nbsp;&nbsp;Suma (`+`) y Resta (`-`) de 32 bits.  
    &nbsp;&nbsp;&nbsp;&nbsp;Multiplicación (`*`) de 16x16 bits.  
    &nbsp;&nbsp;&nbsp;&nbsp;División (`/`) de 16 bits con detección de error.  
    &nbsp;&nbsp;&nbsp;&nbsp;Raíz Cuadrada (`sqr`) de 16 bits.

Así mismo, se añadieron verificaciones para que tengan coherencia matemática las operaciones, así como:  
  &nbsp;&nbsp;&nbsp;&nbsp;Conversión automática de Binario a Decimal (BCD) para mostrar resultados legibles (soporta hasta 65535).    
  &nbsp;&nbsp;&nbsp;&nbsp;Detección de división por cero (muestra `Err`).  
  &nbsp;&nbsp;&nbsp;&nbsp;Detección de secuencia de texto para la raíz cuadrada (sqr).

## Requisitos

### Hardware
* Placa de desarrollo **Colorlight i9** (Lattice ECP5 LFE5U-45F).
* Conversor USB-Serial (FTDI o similar) (En este caso usamos el CMSIS DAP).

### Software (Toolchain Open Source)
* **Yosys:** para síntesis lógica.
* **Nextpnr-ecp5:** Place & Route.
* **Ecppack:** Generación de bitstream.
* **openFPGALoader:** Carga del bitstream a la placa.
* **Icarus Verilog & GTKWave:** Para simulación y verificación.

## Estructura del Proyecto

```text
.
├── Makefile                # Script de automatización (Síntesis, PnR, Simulación)
├── SOC_i9.lpf              # Archivo de restricciones físicas (Pines)
├── README.md               # Documentación
├── src/                    # Código Fuente (SystemVerilog)
│   ├── controlador.sv      # FSM Principal (Cerebro del sistema)
│   ├── uart.sv             # TX/RX
│   ├── multiplicador.sv    # Módulo de multiplicación secuencial
│   ├── divisor.sv          # Módulo de división
│   ├── raiz.sv             # Módulo de raíz cuadrada
│   └── bcd.sv              # Convertidor Binario a BCD (Double Dabble)
└── TestBench/              # Archivos de testbench para simulación
    ├── multiplicador_TB.sv
    ├── divisor_TB.sv
    ├── raiz_TB.sv
    └── bcd_TB.sv
