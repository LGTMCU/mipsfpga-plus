`include "mfp_ahb_lite_matrix_config.vh"

`timescale 1 ns / 100 ps

module mfp_testbench;

    reg         SI_ClkIn;
    reg         SI_ColdReset;
    reg         SI_Reset;

    wire [31:0] HADDR;
    wire [31:0] HRDATA;
    wire [31:0] HWDATA;
    wire        HWRITE;

    reg         EJ_TRST_N_probe;
    reg         EJ_TDI;
    wire        EJ_TDO;
    reg         EJ_TMS;
    reg         EJ_TCK;
    reg         EJ_DINT;

    reg  [17:0] IO_Switches;
    reg  [ 4:0] IO_Buttons;
    wire [17:0] IO_RedLEDs;
    wire [ 8:0] IO_GreenLEDs;

    `ifdef DEMO_LIGHT_SENSOR
    wire [15:0] IO_LightSensor;
    `endif

    reg         UART_RX;
    wire        UART_TX;

    wire        SPI_CS;
    wire        SPI_SCK;
    reg         SPI_SDO;

    //----------------------------------------------------------------

    mfp_system system
    (
        .SI_ClkIn         ( SI_ClkIn         ),
        .SI_ColdReset     ( SI_ColdReset     ),
        .SI_Reset         ( SI_Reset         ),
                                              
        .HADDR            ( HADDR            ),
        .HRDATA           ( HRDATA           ),
        .HWDATA           ( HWDATA           ),
        .HWRITE           ( HWRITE           ),
                                              
        .EJ_TRST_N_probe  ( EJ_TRST_N_probe  ),
        .EJ_TDI           ( EJ_TDI           ),
        .EJ_TDO           ( EJ_TDO           ),
        .EJ_TMS           ( EJ_TMS           ),
        .EJ_TCK           ( EJ_TCK           ),
        .EJ_DINT          ( EJ_DINT          ),
                                              
        .IO_Switches      ( IO_Switches      ),
        .IO_Buttons       ( IO_Buttons       ),
        .IO_RedLEDs       ( IO_RedLEDs       ),
        .IO_GreenLEDs     ( IO_GreenLEDs     ),
                                              
        .UART_RX          ( UART_RX          ),
        .UART_TX          ( UART_TX          ), 

        .SPI_CS           ( SPI_CS           ),
        .SPI_SCK          ( SPI_SCK          ),
        .SPI_SDO          ( SPI_SDO          )
    );

    //----------------------------------------------------------------

    initial
    begin
        SI_ClkIn = 0;

        forever
            # 50 SI_ClkIn = ~ SI_ClkIn;
    end

    initial
    begin
        EJ_TRST_N_probe <= 1'b1;
        EJ_TDI          <= 1'b0;
        EJ_TMS          <= 1'b0;
        EJ_TCK          <= 1'b0;
        EJ_DINT         <= 1'b0;
        IO_Switches     <= 18'b0;
        IO_Buttons      <= 5'b0;
        UART_RX         <= 1'b0;
    end

    initial
    begin
        SI_ColdReset <= 0;
        SI_Reset     <= 0;

        repeat (10)  @(posedge SI_ClkIn);

        SI_ColdReset <= 1;
        SI_Reset     <= 1;

        repeat (20)  @(posedge SI_ClkIn);

        SI_ColdReset <= 0;
        SI_Reset     <= 0;
    end

    //----------------------------------------------------------------

    initial
    begin
        $dumpvars;

        $timeformat
        (
            -9,    // 1 ns
            1,     // Number of digits after decimal point
            "ns",  // suffix
            10     // Max number of digits 
        );
    end

    //----------------------------------------------------------------

    `ifdef MFP_USE_WORD_MEMORY

    reg [7:0] reset_ram [0 : (1 << `MFP_RESET_RAM_ADDR_WIDTH ) - 1];
    reg [7:0] ram       [0 : (1 << `MFP_RAM_ADDR_WIDTH       ) - 1];

    integer i;

    initial
    begin
        $readmemh ("program_1fc00000.hex", reset_ram);

        for (i = 0; i < (1 << `MFP_RESET_RAM_ADDR_WIDTH); i = i + 4)
        begin
            system.ahb_lite_matrix.ahb_lite_matrix.reset_ram.ram.ram [i / 4]
                = { reset_ram [i + 3],
                    reset_ram [i + 2],
                    reset_ram [i + 1],
                    reset_ram [i + 0] };
        end

        $readmemh ("program_00000000.hex", ram);

        for (i = 0; i < (1 << `MFP_RAM_ADDR_WIDTH); i = i + 4)
        begin
            system.ahb_lite_matrix.ahb_lite_matrix.ram.ram.ram [i / 4]
                = { ram [i + 3],
                    ram [i + 2],
                    ram [i + 1],
                    ram [i + 0] };
        end
    end

    `endif

    //----------------------------------------------------------------

    /*
    always @ (negedge SI_ClkIn)
    begin
        if (HADDR == 32'h1fc00058)
        begin
            $display ("Data cache initialized. About to make kseg0 cacheable.");
            $stop;
	end
	else if (HADDR == 32'h00000644)
        begin
	    $display ("Beginning of program code.");
            $stop;
	end
    end
    */

    //----------------------------------------------------------------

    integer cycle; initial cycle = 0;

    always @ (posedge SI_ClkIn)
    begin
        $display ("%5d HCLK %b HADDR %h HRDATA %h HWDATA %h HWRITE %b LEDR %b LEDG %b",
            cycle, system.HCLK, HADDR, HRDATA, HWDATA, HWRITE, IO_RedLEDs, IO_GreenLEDs);

        cycle = cycle + 1;

        if (cycle > 10000)
        begin
            $display ("Timeout");
            $finish;
        end
    end

endmodule
