![](../../workflows/gds/badge.svg) ![](../../workflows/docs/badge.svg) ![](../../workflows/test/badge.svg)

# Brainf\*ck Processor for Tiny Tapeout

## What is this project

This is a second version of my implementation of a [Brainf\*ck Processor](https://github.com/loco-choco/bf-processor/tree/main), with an architecture for the Tiny Tapeout project.

## State Machine

```mermaid
flowchart LR
    Init(((Init))) --> PC((PC++))

    %% subgraph Instruction Loading
    PC --> InstrLoading((Load))
    %% end

    subgraph Add/Subtract Instructions
    direction RL
    InstrLoading -- Data = +/- --> AddInstr1((Addr))
    AddInstr1 --> AddInstr2((Addr))
    AddInstr2 --> PC
    end

    subgraph Shift Instructions
    direction RL
    InstrLoading -- Data = >/< --> ShiftInstr((Reg))
    ShiftInstr --> PC
    end

    subgraph Loop Instructions
    direction RL
    InstrLoading -- Data = [/] --> LoopInstr1((Addr))
    LoopInstr1 --> LoopInstr2((Depth++/--))
    LoopInstr2 --> PC
    end

    subgraph IO Instructions
    direction TB
    InstrLoading -- Data = , --> InputInstr1((WaitingInput))
    InputInstr1 -- Input = 0 --> InputInstr1
    InputInstr1 -- Input = 1 --> InputInstr2((Temp))
    InputInstr2 --> InputInstr3((Addr))
    InputInstr3 --> PC

    InstrLoading -- Data = . --> OutputInstr1((Addr))
    OutputInstr1 --> OutputInstr2((Data))
    OutputInstr2 --> PC
    end
```
