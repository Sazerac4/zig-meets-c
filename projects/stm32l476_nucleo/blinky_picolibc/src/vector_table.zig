//The code below is adapted from this [github repository](https://github.com/haydenridd/stm32-baremetal-zig/tree/main)

comptime {
    @export(&__interrupt_vector, .{
        .name = "__interrupt_vector",
        .section = ".text.init.enter",
        .linkage = .strong,
    });
}

//----------------------------------------------------------------------------
//  Linker generated Symbols
//----------------------------------------------------------------------------
/// Note is given the type "anyopaque" as this symbol is
/// only ever meant to be used by taking the address with &. It doesn't actually "point"
/// to anything valid at all!
extern const __stack: anyopaque;

//----------------------------------------------------------------------------
//  Exception / Interrupt Handler Function Prototype
//----------------------------------------------------------------------------
const IsrFunction = *const fn () callconv(.c) void;

//----------------------------------------------------------------------------
//  External References
//----------------------------------------------------------------------------
extern fn _start() callconv(.c) void;

//----------------------------------------------------------------------------
//  Default Handler for Exceptions / Interrupts
//----------------------------------------------------------------------------
fn defaultHandler() callconv(.c) noreturn {
    @breakpoint();
    while (true) {}
}

//----------------------------------------------------------------------------
//  Exception / Interrupt Handler
//----------------------------------------------------------------------------
const NMI_Handler = @extern(IsrFunction, .{ .name = "NMI_Handler", .linkage = .weak });
const HardFault_Handler = @extern(IsrFunction, .{ .name = "HardFault_Handler", .linkage = .weak });
const MemManage_Handler = @extern(IsrFunction, .{ .name = "MemManage_Handler", .linkage = .weak });
const BusFault_Handler = @extern(IsrFunction, .{ .name = "BusFault_Handler", .linkage = .weak });
const UsageFault_Handler = @extern(IsrFunction, .{ .name = "UsageFault_Handler", .linkage = .weak });
const SVC_Handler = @extern(IsrFunction, .{ .name = "SVC_Handler", .linkage = .weak });
const DebugMon_Handler = @extern(IsrFunction, .{ .name = "DebugMon_Handler", .linkage = .weak });
const PendSV_Handler = @extern(IsrFunction, .{ .name = "PendSV_Handler", .linkage = .weak });
const SysTick_Handler = @extern(IsrFunction, .{ .name = "SysTick_Handler", .linkage = .weak });

// ARM CM4 Specific Interrupts
const WWDG_IRQHandler = @extern(IsrFunction, .{ .name = "WWDG_IRQHandler", .linkage = .weak });
const PVD_PVM_IRQHandler = @extern(IsrFunction, .{ .name = "PVD_PVM_IRQHandler", .linkage = .weak });
const TAMP_STAMP_IRQHandler = @extern(IsrFunction, .{ .name = "TAMP_STAMP_IRQHandler", .linkage = .weak });
const RTC_WKUP_IRQHandler = @extern(IsrFunction, .{ .name = "RTC_WKUP_IRQHandler", .linkage = .weak });
const FLASH_IRQHandler = @extern(IsrFunction, .{ .name = "FLASH_IRQHandler", .linkage = .weak });
const RCC_IRQHandler = @extern(IsrFunction, .{ .name = "RCC_IRQHandler", .linkage = .weak });
const EXTI0_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI0_IRQHandler", .linkage = .weak });
const EXTI1_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI1_IRQHandler", .linkage = .weak });
const EXTI2_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI2_IRQHandler", .linkage = .weak });
const EXTI3_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI3_IRQHandler", .linkage = .weak });
const EXTI4_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI4_IRQHandler", .linkage = .weak });
const DMA1_Channel1_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel1_IRQHandler", .linkage = .weak });
const DMA1_Channel2_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel2_IRQHandler", .linkage = .weak });
const DMA1_Channel3_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel3_IRQHandler", .linkage = .weak });
const DMA1_Channel4_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel4_IRQHandler", .linkage = .weak });
const DMA1_Channel5_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel5_IRQHandler", .linkage = .weak });
const DMA1_Channel6_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel6_IRQHandler", .linkage = .weak });
const DMA1_Channel7_IRQHandler = @extern(IsrFunction, .{ .name = "DMA1_Channel7_IRQHandler", .linkage = .weak });
const ADC1_2_IRQHandler = @extern(IsrFunction, .{ .name = "ADC1_2_IRQHandler", .linkage = .weak });
const CAN1_TX_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_TX_IRQHandler", .linkage = .weak });
const CAN1_RX0_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_RX0_IRQHandler", .linkage = .weak });
const CAN1_RX1_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_RX1_IRQHandler", .linkage = .weak });
const CAN1_SCE_IRQHandler = @extern(IsrFunction, .{ .name = "CAN1_SCE_IRQHandler", .linkage = .weak });
const EXTI9_5_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI9_5_IRQHandler", .linkage = .weak });
const TIM1_BRK_TIM15_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_BRK_TIM15_IRQHandler", .linkage = .weak });
const TIM1_UP_TIM16_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_UP_TIM16_IRQHandler", .linkage = .weak });
const TIM1_TRG_COM_TIM17_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_TRG_COM_TIM17_IRQHandler", .linkage = .weak });
const TIM1_CC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM1_CC_IRQHandler", .linkage = .weak });
const TIM2_IRQHandler = @extern(IsrFunction, .{ .name = "TIM2_IRQHandler", .linkage = .weak });
const TIM3_IRQHandler = @extern(IsrFunction, .{ .name = "TIM3_IRQHandler", .linkage = .weak });
const TIM4_IRQHandler = @extern(IsrFunction, .{ .name = "TIM4_IRQHandler", .linkage = .weak });
const I2C1_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C1_EV_IRQHandler", .linkage = .weak });
const I2C1_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C1_ER_IRQHandler", .linkage = .weak });
const I2C2_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C2_EV_IRQHandler", .linkage = .weak });
const I2C2_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C2_ER_IRQHandler", .linkage = .weak });
const SPI1_IRQHandler = @extern(IsrFunction, .{ .name = "SPI1_IRQHandler", .linkage = .weak });
const SPI2_IRQHandler = @extern(IsrFunction, .{ .name = "SPI2_IRQHandler", .linkage = .weak });
const USART1_IRQHandler = @extern(IsrFunction, .{ .name = "USART1_IRQHandler", .linkage = .weak });
const USART2_IRQHandler = @extern(IsrFunction, .{ .name = "USART2_IRQHandler", .linkage = .weak });
const USART3_IRQHandler = @extern(IsrFunction, .{ .name = "USART3_IRQHandler", .linkage = .weak });
const EXTI15_10_IRQHandler = @extern(IsrFunction, .{ .name = "EXTI15_10_IRQHandler", .linkage = .weak });
const RTC_Alarm_IRQHandler = @extern(IsrFunction, .{ .name = "RTC_Alarm_IRQHandler", .linkage = .weak });
const DFSDM1_FLT3_IRQHandler = @extern(IsrFunction, .{ .name = "DFSDM1_FLT3_IRQHandler", .linkage = .weak });
const TIM8_BRK_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_BRK_IRQHandler", .linkage = .weak });
const TIM8_UP_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_UP_IRQHandler", .linkage = .weak });
const TIM8_TRG_COM_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_TRG_COM_IRQHandler", .linkage = .weak });
const TIM8_CC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM8_CC_IRQHandler", .linkage = .weak });
const ADC3_IRQHandler = @extern(IsrFunction, .{ .name = "ADC3_IRQHandler", .linkage = .weak });
const FMC_IRQHandler = @extern(IsrFunction, .{ .name = "FMC_IRQHandler", .linkage = .weak });
const SDMMC1_IRQHandler = @extern(IsrFunction, .{ .name = "SDMMC1_IRQHandler", .linkage = .weak });
const TIM5_IRQHandler = @extern(IsrFunction, .{ .name = "TIM5_IRQHandler", .linkage = .weak });
const SPI3_IRQHandler = @extern(IsrFunction, .{ .name = "SPI3_IRQHandler", .linkage = .weak });
const UART4_IRQHandler = @extern(IsrFunction, .{ .name = "UART4_IRQHandler", .linkage = .weak });
const UART5_IRQHandler = @extern(IsrFunction, .{ .name = "UART5_IRQHandler", .linkage = .weak });
const TIM6_DAC_IRQHandler = @extern(IsrFunction, .{ .name = "TIM6_DAC_IRQHandler", .linkage = .weak });
const TIM7_IRQHandler = @extern(IsrFunction, .{ .name = "TIM7_IRQHandler", .linkage = .weak });
const DMA2_Channel1_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel1_IRQHandler", .linkage = .weak });
const DMA2_Channel2_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel2_IRQHandler", .linkage = .weak });
const DMA2_Channel3_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel3_IRQHandler", .linkage = .weak });
const DMA2_Channel4_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel4_IRQHandler", .linkage = .weak });
const DMA2_Channel5_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel5_IRQHandler", .linkage = .weak });
const DFSDM1_FLT0_IRQHandler = @extern(IsrFunction, .{ .name = "DFSDM1_FLT0_IRQHandler", .linkage = .weak });
const DFSDM1_FLT1_IRQHandler = @extern(IsrFunction, .{ .name = "DFSDM1_FLT1_IRQHandler", .linkage = .weak });
const DFSDM1_FLT2_IRQHandler = @extern(IsrFunction, .{ .name = "DFSDM1_FLT2_IRQHandler", .linkage = .weak });
const COMP_IRQHandler = @extern(IsrFunction, .{ .name = "COMP_IRQHandler", .linkage = .weak });
const LPTIM1_IRQHandler = @extern(IsrFunction, .{ .name = "LPTIM1_IRQHandler", .linkage = .weak });
const LPTIM2_IRQHandler = @extern(IsrFunction, .{ .name = "LPTIM2_IRQHandler", .linkage = .weak });
const OTG_FS_IRQHandler = @extern(IsrFunction, .{ .name = "OTG_FS_IRQHandler", .linkage = .weak });
const DMA2_Channel6_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel6_IRQHandler", .linkage = .weak });
const DMA2_Channel7_IRQHandler = @extern(IsrFunction, .{ .name = "DMA2_Channel7_IRQHandler", .linkage = .weak });
const LPUART1_IRQHandler = @extern(IsrFunction, .{ .name = "LPUART1_IRQHandler", .linkage = .weak });
const QUADSPI_IRQHandler = @extern(IsrFunction, .{ .name = "QUADSPI_IRQHandler", .linkage = .weak });
const I2C3_EV_IRQHandler = @extern(IsrFunction, .{ .name = "I2C3_EV_IRQHandler", .linkage = .weak });
const I2C3_ER_IRQHandler = @extern(IsrFunction, .{ .name = "I2C3_ER_IRQHandler", .linkage = .weak });
const SAI1_IRQHandler = @extern(IsrFunction, .{ .name = "SAI1_IRQHandler", .linkage = .weak });
const SAI2_IRQHandler = @extern(IsrFunction, .{ .name = "SAI2_IRQHandler", .linkage = .weak });
const SWPMI1_IRQHandler = @extern(IsrFunction, .{ .name = "SWPMI1_IRQHandler", .linkage = .weak });
const TSC_IRQHandler = @extern(IsrFunction, .{ .name = "TSC_IRQHandler", .linkage = .weak });
const LCD_IRQHandler = @extern(IsrFunction, .{ .name = "LCD_IRQHandler", .linkage = .weak });
const RNG_IRQHandler = @extern(IsrFunction, .{ .name = "RNG_IRQHandler", .linkage = .weak });
const FPU_IRQHandler = @extern(IsrFunction, .{ .name = "FPU_IRQHandler", .linkage = .weak });

//----------------------------------------------------------------------------
// Exception / Interrupt Vector table
//----------------------------------------------------------------------------
const __interrupt_vector: VectorTable = .{};

const VectorTable = extern struct {
    initial_stack_pointer: *const anyopaque = &__stack,
    Reset_Handler: IsrFunction = _start,
    NMI_Handler: IsrFunction = NMI_Handler orelse defaultHandler,
    HardFault_Handler: IsrFunction = HardFault_Handler orelse defaultHandler,
    MemManage_Handler: IsrFunction = MemManage_Handler orelse defaultHandler,
    BusFault_Handler: IsrFunction = BusFault_Handler orelse defaultHandler,
    UsageFault_Handler: IsrFunction = UsageFault_Handler orelse defaultHandler,
    reserved1: [4]u32 = undefined,
    SVC_Handler: IsrFunction = SVC_Handler orelse defaultHandler,
    DebugMon_Handler: IsrFunction = DebugMon_Handler orelse defaultHandler,
    reserved2: u32 = undefined,
    PendSV_Handler: IsrFunction = PendSV_Handler orelse defaultHandler,
    SysTick_Handler: IsrFunction = SysTick_Handler orelse defaultHandler,
    WWDG_IRQHandler: IsrFunction = WWDG_IRQHandler orelse defaultHandler,
    PVD_PVM_IRQHandler: IsrFunction = PVD_PVM_IRQHandler orelse defaultHandler,
    TAMP_STAMP_IRQHandler: IsrFunction = TAMP_STAMP_IRQHandler orelse defaultHandler,
    RTC_WKUP_IRQHandler: IsrFunction = RTC_WKUP_IRQHandler orelse defaultHandler,
    FLASH_IRQHandler: IsrFunction = FLASH_IRQHandler orelse defaultHandler,
    RCC_IRQHandler: IsrFunction = RCC_IRQHandler orelse defaultHandler,
    EXTI0_IRQHandler: IsrFunction = EXTI0_IRQHandler orelse defaultHandler,
    EXTI1_IRQHandler: IsrFunction = EXTI1_IRQHandler orelse defaultHandler,
    EXTI2_IRQHandler: IsrFunction = EXTI2_IRQHandler orelse defaultHandler,
    EXTI3_IRQHandler: IsrFunction = EXTI3_IRQHandler orelse defaultHandler,
    EXTI4_IRQHandler: IsrFunction = EXTI4_IRQHandler orelse defaultHandler,
    DMA1_Channel1_IRQHandler: IsrFunction = DMA1_Channel1_IRQHandler orelse defaultHandler,
    DMA1_Channel2_IRQHandler: IsrFunction = DMA1_Channel2_IRQHandler orelse defaultHandler,
    DMA1_Channel3_IRQHandler: IsrFunction = DMA1_Channel3_IRQHandler orelse defaultHandler,
    DMA1_Channel4_IRQHandler: IsrFunction = DMA1_Channel4_IRQHandler orelse defaultHandler,
    DMA1_Channel5_IRQHandler: IsrFunction = DMA1_Channel5_IRQHandler orelse defaultHandler,
    DMA1_Channel6_IRQHandler: IsrFunction = DMA1_Channel6_IRQHandler orelse defaultHandler,
    DMA1_Channel7_IRQHandler: IsrFunction = DMA1_Channel7_IRQHandler orelse defaultHandler,
    ADC1_2_IRQHandler: IsrFunction = ADC1_2_IRQHandler orelse defaultHandler,
    CAN1_TX_IRQHandler: IsrFunction = CAN1_TX_IRQHandler orelse defaultHandler,
    CAN1_RX0_IRQHandler: IsrFunction = CAN1_RX0_IRQHandler orelse defaultHandler,
    CAN1_RX1_IRQHandler: IsrFunction = CAN1_RX1_IRQHandler orelse defaultHandler,
    CAN1_SCE_IRQHandler: IsrFunction = CAN1_SCE_IRQHandler orelse defaultHandler,
    EXTI9_5_IRQHandler: IsrFunction = EXTI9_5_IRQHandler orelse defaultHandler,
    TIM1_BRK_TIM15_IRQHandler: IsrFunction = TIM1_BRK_TIM15_IRQHandler orelse defaultHandler,
    TIM1_UP_TIM16_IRQHandler: IsrFunction = TIM1_UP_TIM16_IRQHandler orelse defaultHandler,
    TIM1_TRG_COM_TIM17_IRQHandler: IsrFunction = TIM1_TRG_COM_TIM17_IRQHandler orelse defaultHandler,
    TIM1_CC_IRQHandler: IsrFunction = TIM1_CC_IRQHandler orelse defaultHandler,
    TIM2_IRQHandler: IsrFunction = TIM2_IRQHandler orelse defaultHandler,
    TIM3_IRQHandler: IsrFunction = TIM3_IRQHandler orelse defaultHandler,
    TIM4_IRQHandler: IsrFunction = TIM4_IRQHandler orelse defaultHandler,
    I2C1_EV_IRQHandler: IsrFunction = I2C1_EV_IRQHandler orelse defaultHandler,
    I2C1_ER_IRQHandler: IsrFunction = I2C1_ER_IRQHandler orelse defaultHandler,
    I2C2_EV_IRQHandler: IsrFunction = I2C2_EV_IRQHandler orelse defaultHandler,
    I2C2_ER_IRQHandler: IsrFunction = I2C2_ER_IRQHandler orelse defaultHandler,
    SPI1_IRQHandler: IsrFunction = SPI1_IRQHandler orelse defaultHandler,
    SPI2_IRQHandler: IsrFunction = SPI2_IRQHandler orelse defaultHandler,
    USART1_IRQHandler: IsrFunction = USART1_IRQHandler orelse defaultHandler,
    USART2_IRQHandler: IsrFunction = USART2_IRQHandler orelse defaultHandler,
    USART3_IRQHandler: IsrFunction = USART3_IRQHandler orelse defaultHandler,
    EXTI15_10_IRQHandler: IsrFunction = EXTI15_10_IRQHandler orelse defaultHandler,
    RTC_Alarm_IRQHandler: IsrFunction = RTC_Alarm_IRQHandler orelse defaultHandler,
    DFSDM1_FLT3_IRQHandler: IsrFunction = DFSDM1_FLT3_IRQHandler orelse defaultHandler,
    TIM8_BRK_IRQHandler: IsrFunction = TIM8_BRK_IRQHandler orelse defaultHandler,
    TIM8_UP_IRQHandler: IsrFunction = TIM8_UP_IRQHandler orelse defaultHandler,
    TIM8_TRG_COM_IRQHandler: IsrFunction = TIM8_TRG_COM_IRQHandler orelse defaultHandler,
    TIM8_CC_IRQHandler: IsrFunction = TIM8_CC_IRQHandler orelse defaultHandler,
    ADC3_IRQHandler: IsrFunction = ADC3_IRQHandler orelse defaultHandler,
    FMC_IRQHandler: IsrFunction = FMC_IRQHandler orelse defaultHandler,
    SDMMC1_IRQHandler: IsrFunction = SDMMC1_IRQHandler orelse defaultHandler,
    TIM5_IRQHandler: IsrFunction = TIM5_IRQHandler orelse defaultHandler,
    SPI3_IRQHandler: IsrFunction = SPI3_IRQHandler orelse defaultHandler,
    UART4_IRQHandler: IsrFunction = UART4_IRQHandler orelse defaultHandler,
    UART5_IRQHandler: IsrFunction = UART5_IRQHandler orelse defaultHandler,
    TIM6_DAC_IRQHandler: IsrFunction = TIM6_DAC_IRQHandler orelse defaultHandler,
    TIM7_IRQHandler: IsrFunction = TIM7_IRQHandler orelse defaultHandler,
    DMA2_Channel1_IRQHandler: IsrFunction = DMA2_Channel1_IRQHandler orelse defaultHandler,
    DMA2_Channel2_IRQHandler: IsrFunction = DMA2_Channel2_IRQHandler orelse defaultHandler,
    DMA2_Channel3_IRQHandler: IsrFunction = DMA2_Channel3_IRQHandler orelse defaultHandler,
    DMA2_Channel4_IRQHandler: IsrFunction = DMA2_Channel4_IRQHandler orelse defaultHandler,
    DMA2_Channel5_IRQHandler: IsrFunction = DMA2_Channel5_IRQHandler orelse defaultHandler,
    DFSDM1_FLT0_IRQHandler: IsrFunction = DFSDM1_FLT0_IRQHandler orelse defaultHandler,
    DFSDM1_FLT1_IRQHandler: IsrFunction = DFSDM1_FLT1_IRQHandler orelse defaultHandler,
    DFSDM1_FLT2_IRQHandler: IsrFunction = DFSDM1_FLT2_IRQHandler orelse defaultHandler,
    COMP_IRQHandler: IsrFunction = COMP_IRQHandler orelse defaultHandler,
    LPTIM1_IRQHandler: IsrFunction = LPTIM1_IRQHandler orelse defaultHandler,
    LPTIM2_IRQHandler: IsrFunction = LPTIM2_IRQHandler orelse defaultHandler,
    OTG_FS_IRQHandler: IsrFunction = OTG_FS_IRQHandler orelse defaultHandler,
    DMA2_Channel6_IRQHandler: IsrFunction = DMA2_Channel6_IRQHandler orelse defaultHandler,
    DMA2_Channel7_IRQHandler: IsrFunction = DMA2_Channel7_IRQHandler orelse defaultHandler,
    LPUART1_IRQHandler: IsrFunction = LPUART1_IRQHandler orelse defaultHandler,
    QUADSPI_IRQHandler: IsrFunction = QUADSPI_IRQHandler orelse defaultHandler,
    I2C3_EV_IRQHandler: IsrFunction = I2C3_EV_IRQHandler orelse defaultHandler,
    I2C3_ER_IRQHandler: IsrFunction = I2C3_ER_IRQHandler orelse defaultHandler,
    SAI1_IRQHandler: IsrFunction = SAI1_IRQHandler orelse defaultHandler,
    SAI2_IRQHandler: IsrFunction = SAI2_IRQHandler orelse defaultHandler,
    SWPMI1_IRQHandler: IsrFunction = SWPMI1_IRQHandler orelse defaultHandler,
    TSC_IRQHandler: IsrFunction = TSC_IRQHandler orelse defaultHandler,
    LCD_IRQHandler: IsrFunction = LCD_IRQHandler orelse defaultHandler,
    reserved3: u32 = undefined,
    RNG_IRQHandler: IsrFunction = RNG_IRQHandler orelse defaultHandler,
    FPU_IRQHandler: IsrFunction = FPU_IRQHandler orelse defaultHandler,
};
