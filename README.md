# RV32I Cache Memory Hierarchy

A complete RTL implementation of a **cache memory hierarchy for an RV32I RISC-V processor** using **SystemVerilog**. This project adds an on-chip cache subsystem between the pipelined core and main memory, reducing average memory access time and demonstrating the classic memory-hierarchy concepts — hits, misses, replacement, write policies, and miss penalties — verified with a custom testbench in Vivado.

> Fill in every `[PLACEHOLDER]` below with the values from your RTL before publishing.

---

## Project Overview

The RV32I 5-stage pipelined core ([RV32I_RISC_V-5_STAGE_PIPELINE](https://github.com/Guru-P169/RV32I_RISC_V-5_STAGE_PIPELINE)) originally accessed instruction and data memory directly in a single cycle. Real systems cannot do that, because main memory is far slower than the core. This project introduces a **cache memory hierarchy** that sits between the processor and main memory so that most accesses are served quickly from small, fast on-chip storage, and only misses pay the cost of going to the next level.

The design is companion work to the [RV32I Gshare Branch Predictor](https://github.com/Guru-P169/rv32i-gshare-branch-predictor), which targets the same core: the predictor reduces control-hazard penalties, while the cache hierarchy reduces memory-access penalties.

### Key Highlights

- Cache hierarchy for the RV32I core: **[PLACEHOLDER: e.g. L1 I-cache + L1 D-cache + main memory]**
- Cache organisation: **[PLACEHOLDER: direct-mapped / N-way set-associative]**, **[PLACEHOLDER: size]**, **[PLACEHOLDER: block size]**
- Replacement policy: **[PLACEHOLDER: e.g. LRU / pseudo-LRU / FIFO / none (direct-mapped)]**
- Write policy: **[PLACEHOLDER: write-back + write-allocate / write-through + no-write-allocate]**
- Cache controller FSM handling hit, miss, refill and write-back
- Verified with a self-checking testbench and waveform analysis

---

## Project Architecture

Architecture diagrams are in [`RV321-Cache_Architecture/`](RV321-Cache_Architecture/).

<!-- Replace the file name below with the actual image in RV321-Cache_Architecture/ -->
![Cache Architecture](RV321-Cache_Architecture/[PLACEHOLDER-image-name].png)

---

## Repository Structure

```
rv32i-cache-memory-hierarchy/
│
├── RV321-Cache_Architecture/    # Architecture / block diagrams
│
├── rtl/                         # SystemVerilog design sources
│   └── [PLACEHOLDER: list modules]
│
├── tb/                          # Testbenches
│   └── [PLACEHOLDER: list testbench files]
│
├── simulation/                  # Simulation waveforms / screenshots
│
├── results/                     # Performance and verification results
│
└── README.md
```

---

## Cache Parameters

| Parameter          | Value                     |
| ------------------ | ------------------------- |
| Address width      | 32 bits                   |
| Cache size         | [PLACEHOLDER]             |
| Block (line) size  | [PLACEHOLDER]             |
| Associativity      | [PLACEHOLDER]             |
| Number of sets     | [PLACEHOLDER]             |
| Replacement policy | [PLACEHOLDER]             |
| Write policy       | [PLACEHOLDER]             |
| Miss penalty       | [PLACEHOLDER] cycles      |

### Address Breakdown

```
 31                                   0
 +-----------+-----------+-------------+
 |    Tag    |   Index   | Block offset|
 +-----------+-----------+-------------+
   [PLACEHOLDER: widths computed from the parameters above]
```

---

## RTL Modules

| Module                  | Description                                               |
| ----------------------- | --------------------------------------------------------- |
| `[PLACEHOLDER].sv`      | Top-level integration of core, caches and main memory     |
| `[PLACEHOLDER].sv`      | Cache data array (block storage)                          |
| `[PLACEHOLDER].sv`      | Tag, valid and dirty bit arrays                           |
| `[PLACEHOLDER].sv`      | Cache controller FSM (hit / miss / refill / write-back)   |
| `[PLACEHOLDER].sv`      | Replacement logic                                         |
| `[PLACEHOLDER].sv`      | Main memory model with configurable latency               |

---

## Cache Operation

| Event           | Behaviour                                                              |
| --------------- | ---------------------------------------------------------------------- |
| Read hit        | Data returned from the cache with no stall                             |
| Read miss       | Pipeline stalls; block fetched from the next level and the line refilled |
| Write hit       | [PLACEHOLDER: update cache line and set dirty bit / write through]     |
| Write miss      | [PLACEHOLDER: write-allocate / no-write-allocate behaviour]            |
| Eviction        | [PLACEHOLDER: write back dirty victim before refill]                   |

### Controller States

[PLACEHOLDER: list your FSM states, e.g. IDLE → COMPARE_TAG → WRITE_BACK → ALLOCATE → IDLE]

---

## Features

- Parameterisable cache organisation
- Tag / valid / dirty bit management
- Cache controller FSM with pipeline stall interface
- Configurable main-memory latency
- Hit / miss counters for performance measurement
- Self-checking testbench

---

## Verification

The testbench in `tb/` exercises the cache with access patterns designed to hit every controller path: cold (compulsory) misses, repeated hits, conflict misses, capacity misses, dirty-line eviction and write-back, and read-after-write consistency.

[PLACEHOLDER: describe the exact test programs / access patterns and the pass/fail checks your testbench performs.]

---

## Simulation Results

### Waveforms

Waveform captures are in [`simulation/`](simulation/).

![Simulation Waveform](simulation/[PLACEHOLDER-waveform].png)

### Performance Results

Measured results are in [`results/`](results/).

| Metric               | Value         |
| -------------------- | ------------- |
| Total accesses       | [PLACEHOLDER] |
| Hits                 | [PLACEHOLDER] |
| Misses               | [PLACEHOLDER] |
| Hit rate             | [PLACEHOLDER] |
| Average access time  | [PLACEHOLDER] |

---

## Concepts Covered

- Memory hierarchy design
- Cache organisation (mapping, tags, indexing)
- Locality of reference (temporal and spatial)
- Compulsory, capacity and conflict misses
- Replacement and write policies
- Cache controller FSM design
- Pipeline stalling on memory misses
- Average memory access time (AMAT)
- RTL design methodology and testbench verification

---

## Tools & Technologies

- **SystemVerilog**
- **Vivado Simulator**
- **Visual Studio Code**
- **Git**
- **GitHub**

---

## Related Projects

- [RV32I 5-Stage Pipelined RISC-V Core](https://github.com/Guru-P169/RV32I_RISC_V-5_STAGE_PIPELINE)
- [RV32I Gshare Branch Predictor](https://github.com/Guru-P169/rv32i-gshare-branch-predictor)

---

## Future Enhancements

- Multi-level hierarchy (L2 cache)
- Higher associativity and pseudo-LRU replacement
- Write buffer and non-blocking cache
- Prefetching
- Full integration with the branch predictor in a single core
- SystemVerilog Assertions (SVA) and functional coverage

---

## Author

**Guru P**

Electronics and Communication Engineering Student

### Areas of Interest

- RTL Design
- ASIC Design
- Functional Verification
- Digital Design
- VLSI Frontend Design

GitHub: **<https://github.com/Guru-P169>**

---

⭐ If you found this project useful or interesting, consider giving it a star on GitHub.
