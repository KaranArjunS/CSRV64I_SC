#include "Vcsrv64i.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    Vcsrv64i* top = new Vcsrv64i;

    VerilatedVcdC* tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("wave.vcd");

    // -------------------------
    // RESET SEQUENCE (IMPORTANT)
    // -------------------------
    top->clk = 0;
    top->reset = 1;
    top->eval();
    tfp->dump(0);

    // Hold reset for a few cycles
    for (int i = 1; i <= 4; i++) {
        top->clk ^= 1;
        top->eval();
        tfp->dump(i);
    }

    // RELEASE RESET
    top->reset = 0;

    // -------------------------
    // RUN SIMULATION
    // -------------------------
    for (int i = 5; i < 100; i++) {
        top->clk ^= 1;
        top->eval();
        tfp->dump(i);
    }

    tfp->close();
    delete top;
    return 0;
}