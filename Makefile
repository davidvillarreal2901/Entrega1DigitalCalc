PROYECTO = controlador
BUILD_DIR = build

# Archivos fuente (Todos planos en src/)
OBJS = src/controlador.sv
OBJS += src/uart.sv
OBJS += src/multiplicador.sv
OBJS += src/divisor.sv
OBJS += src/raiz.sv
OBJS += src/bcd.sv

# FPGA Config
# CORRECCIÓN: Volvemos a usar el nombre real de tu archivo
LPF_FILE = SOC_i9.lpf
CHIP = colorlight-i9

all: $(PROYECTO).bit

$(PROYECTO).json: $(OBJS)
	mkdir -p $(BUILD_DIR)
	# Usamos -sv para SystemVerilog
	yosys -p 'read_verilog -sv $(OBJS); synth_ecp5 -top controlador -json $(BUILD_DIR)/$@'

$(PROYECTO).config: $(PROYECTO).json
	nextpnr-ecp5 --json $(BUILD_DIR)/$< --lpf $(LPF_FILE) --textcfg $(BUILD_DIR)/$@ --45k --package CABGA381 --speed 6 --lpf-allow-unconstrained

$(PROYECTO).bit: $(PROYECTO).config
	ecppack --compress $(BUILD_DIR)/$< --bit $(BUILD_DIR)/$@

cargar: $(PROYECTO).bit
	sudo openFPGALoader -b $(CHIP) $(BUILD_DIR)/$(PROYECTO).bit

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all cargar clean

# --- REGLAS DE SIMULACIÓN ---

# Configuración del Simulador
SIM = iverilog -g2012
VVP = vvp

# 1. Simulación del Multiplicador
sim_mult:
	$(SIM) -o $(BUILD_DIR)/multiplicador_TB.out src/multiplicador.sv TestBench/multiplicador_TB.sv
	$(VVP) $(BUILD_DIR)/multiplicador_TB.out
	gtkwave $(BUILD_DIR)/multiplicador.vcd &

# 2. Simulación del Divisor
sim_div:
	$(SIM) -o $(BUILD_DIR)/divisor_TB.out src/divisor.sv TestBench/divisor_TB.sv
	$(VVP) $(BUILD_DIR)/divisor_TB.out
	gtkwave $(BUILD_DIR)/divisor.vcd &

# 3. Simulación de la Raíz Cuadrada
sim_raiz:
	$(SIM) -o $(BUILD_DIR)/raiz_TB.out src/raiz.sv TestBench/raiz_TB.sv
	$(VVP) $(BUILD_DIR)/raiz_TB.out
	gtkwave $(BUILD_DIR)/raiz.vcd &

# 4. Simulación del BCD
sim_bcd:
	$(SIM) -o $(BUILD_DIR)/bcd_TB.out src/bcd.sv TestBench/bcd_TB.sv
	$(VVP) $(BUILD_DIR)/bcd_TB.out
	gtkwave $(BUILD_DIR)/bcd.vcd &

# Limpieza de archivos de simulación
clean_sim:
	rm -f $(BUILD_DIR)/*.out $(BUILD_DIR)/*.vcd