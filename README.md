# Calculadora FPGA en SystemVerilog - Colorlight i9  
Juan Felipe Arias Ruiz             - CC 1001077136  
Laura Camila Barrera León          - CC 1016942896  
David Ricardo Villarreal Archila   - CC 1005154067  

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
```

---
## Requisitos
- **iverilog** → compilador y simulador de Verilog (Icarus Verilog).  
- **gtkwave** → visualización de señales (archivos `.vcd`).  
- **make** y **build-essential** → utilidades para compilar con los Makefiles.  
- **gcc-riscv64-unknown-elf** → compilador cruzado para ensamblador RISC-V.  

### MacOS 🍏
Necesitamos tener HomeBrew instalado
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
luego
```bash
brew install icarus-verilog gtkwave
brew install yosys nextpnr --with-gui
brew install project-trellis
brew install openfpgaloader
brew install minicom
```

### Linux 🐧
```bash
sudo apt update
sudo apt install iverilog gtkwave make build-essential gcc-riscv64-unknown-elf minicom
```

---
## Clonar github

a continuacion se clona el repositorio github para poder empezar a trabajar en el
```bash
git clone https://github.com/davidvillarreal2901/Entrega1DigitalCalc.git
```

---
## Flujo de trabajo
### Simulación
Antes de cargar el diseño, podemos verificar que los módulos matemáticos funcionan correctamente usando los testbench incluidos para cada módulo.

```bash
make sim_mult	# Simula la multiplicación (ej. 85 * 51)
make sim_div	# Simula la división y errores (ej. /0)
make sim_raiz	# Simula la raíz cuadrada
make sim_bcd	# Simula la conversión a decimal
```
Esto compilará el diseño y abrirá GTKWave automáticamente para ver las señales de cada módulo.

### Implementación en la FPGA
conectar por medio de USB a través del programador o en nuestro caso del CMSIS DAP
y ahí dentro de la carpeta podemos correr
```bash
make clean     # Para limpiar el build ya creado
make cargar    # Para crear los archivos del build y subirlos a la FPGA que detecte con la configuración 
```

Y para poder visualizar las operaciones y su respectivo resultado debemos correr minicom (Recomiendo abrirlo en otra ventana de terminal si es MacOS porque el ctrl a para salir no funciona igual) así:

```bash
minicom -D /dev/cu.usbmodem102 -b 115200 #(depende del puerto al que está conectada la FPGA, para MacOS /dev/cu.usb... para Linux /dev/tty... )
# El 115200 son los baudios
```
