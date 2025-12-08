# 🏎️ Assembly Racing Game - Progressive Development

A fully-featured racing game written in x86 assembly language for DOS, developed progressively across 6 phases from static rendering to audio-integrated gameplay.

## 🎮 Game Overview

Navigate through traffic, collect coins, manage fuel, and survive as long as possible in this retro-style racing game. Built entirely in x86 assembly language, this project demonstrates low-level programming, hardware interaction, and game development fundamentals.

## ✨ Features

- **🚗 3-Lane Racing Mechanics**: Smooth lane switching with vertical movement control
- **🚙 Dynamic Obstacles**: Random spawning traffic with intelligent collision detection
- **💰 Collectible Items**: 
  - Coins ($) for scoring points
  - Fuel (F) pickups for survival
- **⛽ Fuel Management**: Real-time fuel depletion with refill system
- **🎵 Background Music**: PC speaker audio via timer interrupts
- **👤 Player System**: Name and roll number input with validation
- **🎯 Game States**: Complete flow with intro, instructions, gameplay, pause, and game over
- **📊 HUD Display**: Real-time score and fuel level indicators
- **💥 Collision Effects**: Visual fade-out animations on collision
- **⏸️ Pause Functionality**: ESC key for pause/resume with quit confirmation

## 📁 Project Structure

The project is organized into 6 progressive development phases:

```
📦 assembly-racing-game
├── phase1.asm    # Static Scene Rendering
├── phase2.asm    # Dynamic Animation System
├── phase3.asm    # Advanced Input & Game Logic
├── phase4.asm    # Player Information System
├── phase5.asm    # Complete Gameplay Experience
└── phase6.asm    # Audio Integration & Polish
```

### Phase Breakdown

| Phase | Description | Key Features |
|-------|-------------|--------------|
| **Phase 1** | Static Scene Rendering | Road generation, lane markers, static cars |
| **Phase 2** | Dynamic Animation | Scrolling, spawning, collision detection, HUD |
| **Phase 3** | Advanced Input | Keyboard ISR, pause system, game states |
| **Phase 4** | Player Info System | Intro screens, text input, instructions |
| **Phase 5** | Complete Gameplay | High scores, difficulty scaling, polished mechanics |
| **Phase 6** | Audio Integration | Background music, timer ISR, multitasking |

## 🛠️ Technical Details

### System Requirements
- **Assembler**: NASM (Netwide Assembler)
- **Platform**: DOS or DOSBox emulator
- **Architecture**: x86 (16-bit Real Mode)
- **Display**: VGA Text Mode (80x25 characters)
- **Memory Model**: Tiny (.COM executable, ORG 0x0100)

### Technical Implementation

**Graphics & Display:**
- Direct video memory manipulation (0xB800:0000)
- Character-based graphics using ASCII/extended ASCII
- Custom color attributes for visual effects
- 80x25 text mode rendering

**Input Handling:**
- Custom keyboard ISR (INT 9h hooking)
- Non-blocking input for smooth gameplay
- Key press/release detection
- Multiple simultaneous key states

**Interrupts Used:**
- `INT 10h` - BIOS Video Services
- `INT 16h` - BIOS Keyboard Services
- `INT 21h` - DOS Services
- `INT 8h` - Timer Interrupt (18.2 Hz)
- `INT 9h` - Keyboard Interrupt

**Audio System:**
- PC Speaker programming (Port 61h, 43h, 42h)
- Timer-based frequency generation
- Non-blocking background music
- ISR chaining for multitasking

**Game Architecture:**
- Frame-based game loop
- Object pooling for obstacles/collectibles
- Collision detection with bounding boxes
- State machine for game flow

## 🚀 Build & Run Instructions

### Prerequisites
1. **Install NASM**: Download from [nasm.us](https://www.nasm.us/)
2. **Install DOSBox**: Download from [dosbox.com](https://www.dosbox.com/)

### Building the Game

Open terminal/command prompt and navigate to project directory:

```bash
# Assemble any phase (replace X with 1-6)
nasm phaseX.asm -o phaseX.com
```

Example for Phase 6 (complete game):
```bash
nasm phase6.asm -o phase6.com
```

### Running in DOSBox

**Method 1: Direct Launch**
```bash
dosbox phase6.com
```

**Method 2: Mount Directory**
```
dosbox
mount c /path/to/your/project
c:
phase6.com
```

**Method 3: DOSBox Config**
Add to your dosbox.conf:
```
[autoexec]
mount c /path/to/your/project
c:
phase6.com
```

## 🎯 How to Play

### Controls
- **← Left Arrow**: Move to left lane
- **→ Right Arrow**: Move to right lane  
- **↑ Up Arrow**: Move car forward
- **↓ Down Arrow**: Move car backward
- **ESC**: Pause game / Open quit menu
- **Y**: Confirm quit (when prompted)
- **N**: Cancel quit (when prompted)
- **ENTER**: Continue through menus/screens

### Gameplay Objectives
1. **Avoid Obstacles**: Don't collide with blue cars
2. **Collect Coins ($)**: Each coin adds 10 points to your score
3. **Collect Fuel (F)**: Each fuel pickup adds 20% to your tank
4. **Survive**: Fuel depletes over time - keep collecting fuel!
5. **Score High**: The longer you survive, the higher your score

### Game Mechanics
- **Fuel System**: Fuel decreases automatically over time
- **Dynamic Spawning**: Obstacles appear randomly in all lanes
- **Collision Detection**: Hitting an obstacle ends the game
- **Scoring**: Collect coins to increase your score
- **Progressive Difficulty**: Game speed may increase over time

## 📊 Game Flow

```
Introduction Screen
       ↓
Player Name Input
       ↓
Roll Number Input
       ↓
Instructions Screen
       ↓
   Gameplay
    ↙    ↘
Pause    Collision/Out of Fuel
   ↓           ↓
Resume    Game Over Screen
   ↑           ↓
   └──────── Exit
```

## 🎨 Visual Elements

**Road Layout:**
```
╔════════════════════════════════════════════════════════════╗
║ GRASS │         LANE 1  │  LANE 2  │  LANE 3         │ GRASS ║
║       │    🚗   :  :    │  :  :    │    :  :         │       ║
║       │         :  :    │  :  :    │    :  :    🚙   │       ║
║       │         :  :    │  :  :  $ │    :  :         │       ║
║       │    F    :  :    │  :  :    │    :  :         │       ║
╚════════════════════════════════════════════════════════════╝
```

**Legend:**
- 🚗 Red Car (Player)
- 🚙 Blue Car (Obstacle)
- $ Yellow Coin (Score +10)
- F Fuel Pickup (Fuel +20%)
- : Lane Markers

## 🧠 Key Programming Concepts

This project demonstrates:

- **Memory Management**: Direct memory access and manipulation
- **Interrupt Handling**: Custom ISR development and interrupt hooking
- **Real-time Systems**: Frame-based game loop with timing control
- **Hardware Programming**: Video memory, keyboard controller, PC speaker
- **State Management**: Game state machines and flow control
- **Collision Detection**: Bounding box intersection algorithms
- **Procedural Generation**: Random spawning with constraints
- **Multitasking**: Simultaneous audio and game logic execution
- **Low-level Graphics**: Character-based rendering pipeline
- **Input Processing**: Non-blocking keyboard handling

## 📚 Learning Outcomes

Working through this project teaches:

1. **x86 Assembly Language**: Syntax, instructions, and register usage
2. **DOS Programming**: COM file format, DOS interrupts, memory model
3. **Hardware Interaction**: Direct hardware access without OS abstraction
4. **Game Loop Architecture**: Update-render cycles and timing
5. **Interrupt Programming**: ISR creation, hooking, and chaining
6. **Memory Addressing**: Segment:offset addressing, video memory
7. **Optimization**: Efficient assembly code for real-time performance
8. **Debugging**: Low-level debugging without modern tools

## 🎓 Academic Information

**Course**: Computer Organization and Assembly Language (COAL)  
**Level**: Undergraduate Computer Science  
**Platform**: x86 Assembly (16-bit)  
**Environment**: DOS / DOSBox  
**Development Approach**: Incremental (6 phases)

## 🐛 Known Issues & Limitations

- Runs only in DOS/DOSBox environment (16-bit real mode)
- Limited to text-mode graphics (no pixel graphics)
- PC speaker audio (monophonic, simple tones)
- Fixed resolution (80x25 text mode)
- Single-player only

## 🔧 Troubleshooting

**Problem**: Game runs too fast
- **Solution**: Adjust `DELAY_HIGH` and `DELAY_LOW` constants in the code

**Problem**: Music doesn't play
- **Solution**: Ensure DOSBox audio is enabled in configuration

**Problem**: Controls not responding
- **Solution**: Make sure DOSBox window has focus, check keyboard ISR is hooked

**Problem**: Assembly errors
- **Solution**: Ensure using NASM assembler, check file paths and syntax

## 📝 Development Notes

### Code Organization
- All phases are standalone complete programs
- Each phase can be assembled and run independently
- Later phases include all features from previous phases
- Code is well-commented for educational purposes

### Optimization Considerations
- Direct video memory access for speed
- Minimal use of BIOS interrupts in game loop
- Efficient collision detection algorithms
- Optimized rendering routines

## 🙏 Acknowledgments

- NASM development team for the excellent assembler
- DOSBox team for the DOS emulation environment
- COAL course instructors and resources
- x86 assembly programming community

---

**⭐ If you find this project helpful for learning assembly programming, please consider starring the repository!***Made with ❤️ using x86 Assembly Language*
