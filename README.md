# Notes
changed C flags to export CFLAGS="-march=nocona -ftree-vectorize -fPIC -fstack-protector-strong -O2 -ffunction-sections -pipe"
to avoid problems with g++.

## RNN Extensions

This repo is a fork of the PULPissimo repo.
The RNN Extensions (related to the Huawei Project) have been implemented here.
Follow the instructions below, they include both the standard flow and the RNN ASIP specific extensions to the flow:


## PULPissimo

![](doc/pulpissimo_archi.png)

PULPissimo is the microcontroller architecture of the more recent PULP chips,
part of the ongoing "PULP platform" collaboration between ETH Zurich and the
University of Bologna - started in 2013.

PULPissimo, like PULPino, is a single-core platform. However, it represents a
significant step ahead in terms of completeness and complexity with respect to
PULPino - in fact, the PULPissimo system is used as the main System-on-Chip
controller for all recent multi-core PULP chips, taking care of autonomous I/O,
advanced data pre-processing, external interrupts, etc.
The PULPissimo architecture includes:

- Either the RI5CY core or the Ibex one as main core
- Autonomous Input/Output subsystem (uDMA)
- New memory subsystem
- Support for Hardware Processing Engines (HWPEs)
- New simple interrupt controller
- New peripherals
- New SDK

RISCY is an in-order, single-issue core with 4 pipeline stages and it has
an IPC close to 1, full support for the base integer instruction set (RV32I),
compressed instructions (RV32C) and multiplication instruction set extension
(RV32M). It can be configured to have single-precision floating-point
instruction set extension (RV32F). It implements several ISA extensions
such as: hardware loops, post-incrementing load and store instructions,
bit-manipulation instructions, MAC operations, support fixed-point operations,
packed-SIMD instructions and the dot product. It has been designed to increase
the energy efficiency of in ultra-low-power signal processing applications.
RISCY implementes a subset of the 1.10 privileged specification.
It includes an optional PMP and the possibility to have a subset of the USER MODE.
RISCY implement the RISC-V Debug spec 0.13.
Further information about the core can be found at
http://ieeexplore.ieee.org/abstract/document/7864441/
and in the documentation of the IP.

Ibex, formely zero-riscy, is an in-order, single-issue core with 2 pipeline stages and it
has full support for the base integer instruction set (RV32I) and
compressed instructions (RV32C).
It can be configured to have multiplication instruction set extension (RV32M)
and the reduced number of registers extension (RV32E).
It has been originally designed at ETH to target ultra-low-power and ultra-low-area constraints.
Ibex is now part of the LowRISC non-profit community.
It implementes a subset of the 1.11 privileged specification and the RISC-V Debug spec 0.13.
Further information about the core can be found at
http://ieeexplore.ieee.org/document/8106976/
and in the documentation of the IP.

PULPissimo includes a new efficient I/O subsystem via a uDMA (micro-DMA) which
communicates with the peripherals autonomously. The core just needs to program
the uDMA and wait for it to handle the transfer.
Further information about the core can be found at
http://ieeexplore.ieee.org/document/8106971/
and in the documentation of the IP.

PULPissimo supports I/O on interfaces such as:

- SPI (as master)
- I2S
- Camera Interface (CPI)
- I2C
- UART
- JTAG

PULPissimo also supports integration of hardware accelerators (Hardware
Processing Engines) that share memory with the RI5CY core and are programmed on
the memory map. An example accelerator, performing multiply-accumulate on a
vector of fixed-point values, can be found in `ips/hwpe-mac-engine` (after
updating the IPs: see below in the Getting Started section).
The `ips/hwpe-stream` and `ips/hwpe-ctrl` folders contain the IPs necessary to
plug streaming accelerators into a PULPissimo or PULP system on the data and
control plane.
For further information on how to design and integrate such accelerators,
see `ips/hwpe-stream/doc` and https://arxiv.org/abs/1612.05974.


## Getting Started
Follow the instructions in the ```RNNASIP``` repo to install the SDK.

## Building the RTL simulation platform
To build the RTL simulation platform, start by getting the latest version of the
IPs composing the PULP system:
```
./update-ips
./switch_to_rnn_ips
./setup_special.sh
```
This will download all the required IPs, solve dependencies and generate the
scripts by calling 

```
./generate-scripts
```

You can build the simulation platform by doing
the following:
```
source setup/vsim.sh
make clean build
```
This command builds a version of the simulation platform with no dependencies on
external models for peripherals. See below (Proprietary verification IPs) for
details on how to plug in some models of real SPI, I2C, I2S peripherals.

## Post-synth Simulation
To build the system for post-synth simulation use the following commands (if needed change the synthesized netlist in the corresponding makefile: sim/vcompile/ips/riscv_gate.mk):
```
source setup/vsim.sh
cd sim/
make clean lib gate_build opt
```
If there are X's appearing in the simulation and they actually start within the clock gating cells, this is due to (unnecessary) timing checks. Either turn them off in modelsim or comment out the timing check for the clock gating cell (i.e. SC8T_CKGPRELATNX*_CSC2*L).

## Downloading and running tests
Finally, you can download and run the basic tests; for that you can checkout the following repositories:

Runtime tests: https://github.com/pulp-platform/pulp-rt-examples

Now you can change directory to your favourite test e.g.: for an hello world
test, run
```
cd pulp-rt-examples/hello
make clean all run
```
The open-source simulation platform relies on JTAG to emulate preloading of the
PULP L2 memory. If you want to simulate a more realistic scenario (e.g.
accessing an external SPI Flash), look at the sections below.

In case you want to see the Modelsim GUI, just type
```
make run gui=1
```
before starting the simulation.

If you want to save a (compressed) VCD for further examination, type
```
make run vsim/script=export_run.tcl
```
before starting the simulation. You will find the VCD in
`build/<SRC_FILE_NAME>/pulpissimo/export.vcd.gz` where
`<SRC_FILE_NAME>` is the name of the C source of the test.


## Requirements
The RTL platform has the following requirements:
- Relatively recent Linux-based operating system; we tested *Ubuntu 16.04* and
  *CentOS 7*.
- Mentor ModelSim in reasonably recent version (we tested it with version *10.6b*
-- the free version provided by Altera is only partially working, see issue #12).
- Python 3.4, with the `pyyaml` module installed (you can get that with
  `pip3 install pyyaml`).
- The SDK has its own dependencies, listed in
  https://github.com/pulp-platform/pulp-sdk/blob/master/README.md

## Repository organization
The PULP and PULPissimo platforms are highly hierarchical and the Git
repositories for the various IPs follow the hierarchy structure to keep maximum
flexibility.
Most of the complexity of the IP updating system are hidden behind the
`update-ips` and `generate-scripts` Python scripts; however, a few details are
important to know:
- Do not assume that the `master` branch of an arbitrary IP is stable; many
  internal IPs could include unstable changes at a certain point of their
  history. Conversely, in top-level platforms (`pulpissimo`, `pulp`) we always
  use *stable* versions of the IPs. Therefore, you should be able to use the
  `master` branch of `pulpissimo` safely.
- By default, the IPs will be collected from GitHub using HTTPS. This makes it
  possible for everyone to clone them without first uploading an SSH key to
  GitHub. However, for development it is often easier to use SSH instead,
  particularly if you want to push changes back.
  To enable this, just replace `https://github.com` with `git@github.com` in the
  `ipstools_cfg.py` configuration file in the root of this repository.

The tools used to collect IPs and create scripts for simulation have many
features that are not necessarily intended for the end user, but can be useful
for developers; if you want more information, e.g. to integrate your own
repository into the flow, you can find documentation at
https://github.com/pulp-platform/IPApproX/blob/master/README.md

## External contributions
The supported way to provide external contributions is by forking one of our
repositories, applying your patch and submitting a pull request where you
describe your changes in detail, along with motivations.
The pull request will be evaluated and checked with our regression test suite
for possible integration.
If you want to replace our version of an IP with your GitHub fork, just add
`group: YOUR_GITHUB_NAMESPACE` to its entry in `ips_list.yml` or
`ips/pulp_soc/ips_list.yml`.
While we are quite relaxed in terms of coding style, please try to follow these
recommendations:
https://github.com/pulp-platform/ariane/blob/master/CONTRIBUTING.md

## Known issues
The current version of the PULPissimo platform does not include yet an FPGA port
or example scripts for ASIC synthesis; both things may be deployed in the
future.
The `ipstools` includes only partial support for simulation flows different from
ModelSim/QuestaSim.

## Support & Questions
For support on any issue related to this platform or any of the IPs, please add
an issue to our tracker on https://github.com/pulp-platform/pulpissimo/issues
