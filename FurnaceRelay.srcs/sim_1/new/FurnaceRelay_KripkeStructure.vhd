----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 26.02.2023 10:16:27
-- Design Name: 
-- Module Name: FurnaceRelay_KripkeStructure - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use work.FurnaceRelay_KripkeStates.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FurnaceRelay_KripkeStructure is
--  Port ( );
end FurnaceRelay_KripkeStructure;

architecture Behavioral of FurnaceRelay_KripkeStructure is

    type AllSignals_t is record
        EXTERNAL_demand: std_logic_vector(1 downto 0);
        EXTERNAL_Heat: std_logic;
        EXTERNAL_RelayOn: std_logic;
        FurnaceRelay_currentState: std_logic_vector(1 downto 0);
        FurnaceRelay_previousRinglet: std_logic_vector(1 downto 0);
        FurnaceRelay_internalState: std_logic_vector(2 downto 0);
        reset: std_logic;
    end record AllSignals_t;
    
    type Snapshots_t is array(0 to 728) of AllSignals_t;
    type KripkeEdge_t is array(0 to 1) of AllSignals_t;
    type KripkeStates_t is array (0 to 728) of KripkeEdge_t;
    type InitialToFROffStates_t is array(0 to 728) of FurnaceRelay_State_FROff_Read;
    type InitialToFROnStates_t is array(0 to 728) of FurnaceRelay_State_FROn_Read;
    
    -- Initial Execution.
    type InitialWrite_t is record
        executeOnEntry: boolean;
        observed: boolean;
    end record InitialWrite_t;
    type InitialRead_t is record
        executeOnEntry: boolean;
        observed: boolean;
    end record InitialRead_t;
    type InitialRinglet_t is record
        read: InitialRead_t;
        write: InitialWrite_t;
        observed: boolean;
    end record InitialRinglet_t;
    type InitialEdgeToFROff_t is record
        fromExecuteOnEntry: boolean;
        toState: FurnaceRelay_State_FROff_Read;
        observed: boolean;
    end record InitialEdgeToFROff_t;
    type InitialEdgeToFROn_t is record
        fromExecuteOnEntry: boolean;
        toState: FurnaceRelay_State_FROn_Read;
        observed: boolean;
    end record InitialEdgeToFROn_t;
    type InitialEdgeToInitial_t is record
        fromExecuteOnEntry: boolean;
        observed: boolean;
    end record InitialEdgeToInitial_t;
    type InitialReads_t is array (0 to 0) of InitialRead_t;
    type InitialWrites_t is array (0 to 0) of InitialWrite_t;
    type InitialRinglets_t is array (0 to 0) of InitialRinglet_t;
    type InitialFROffEdges_t is array(0 to 728) of InitialEdgeToFROff_t;
    type InitialFROnEdges_t is array(0 to 80) of InitialEdgeToFROn_t;
    type InitialInitialEdges_t is array(0 to 1) of InitialEdgeToInitial_t;
    
    signal initialReads: InitialReads_t;
    signal initialWrites: InitialWrites_t;
    signal initialFROffEdges: InitialFROffEdges_t;
    signal initialFROnEdges: InitialFROnEdges_t;
    signal initialInitialEdges: InitialInitialEdges_t;
    signal initialRinglets: InitialRinglets_t;
    signal initialCurrentState: std_logic_vector(1 downto 0) := "00";
    signal initialPreviousRinglet: std_logic_vector(1 downto 0) := "ZZ";
    signal initialIsInitialised: boolean := false;
    signal initialInternalState: std_logic_vector(2 downto 0);
    signal initialCounter: natural := 0;
    
    -- FROff Execution
    type FROffRead_t is record
        executeOnEntry: boolean;
        values: FurnaceRelay_State_FROff_Read;
        observed: boolean;
    end record FROffRead_t;
    type FROffWrite_t is record
        executeOnEntry: boolean;
        values: FurnaceRelay_State_FROff_Write;
        observed: boolean;
    end record FROffWrite_t;
    type FROff_Ringlet_t is record
        read: FROffRead_t;
        write: FROffWrite_t;
        observed: boolean;
    end record FROff_Ringlet_t;
    type FROffReads_t is array(0 to 728) of FROffRead_t;
    type FROffWrites_t is array(0 to 728) of FROffWrite_t;
    type FROffRinglets_t is array(0 to 728) of FROff_Ringlet_t;
    type FROff_Demands_t is array(0 to 728) of std_logic_vector(1 downto 0);
    type FROff_Heats_t is array(0 to 728) of std_logic;
    type FROff_RelayOns_t is array(0 to 728) of std_logic;
    type FROff_CurrentStates_t is array(0 to 728) of std_logic_vector(1 downto 0);
    type FROff_Previousringlets_t is array(0 to 728) of std_logic_vector(1 downto 0);
    type FROff_Resets_t is array(0 to 728) of std_logic;
    signal frOff_demands: FROff_Demands_t;
    signal frOff_Heats: FROff_Heats_t;
    signal frOff_RelayOns: FROff_RelayOns_t;
    signal frOffCurrentStates: FROff_CurrentStates_t;
    signal frOffPreviousringlets: FROff_PreviousRinglets_t;
    signal frOffResets: FROff_Resets_t := (others => '0');
    signal frOffReads: FROffReads_t;
    signal frOffWrites: FROffWrites_t;
    signal frOffRinglets: FROffRinglets_t;
    signal frOffInternalState: std_logic_vector(2 downto 0);
    
    -- FROn Execution
    type FROnRead_t is record
        values: FurnaceRelay_State_FROn_Read;
        observed: boolean;
    end record FROnRead_t;
    type FROnWrite_t is record
        values: FurnaceRelay_State_FROn_write;
        observed: boolean;
    end record FROnWrite_t;
    type FROn_Ringlet_t is record
        read: FROnRead_T;
        write: FROnWrite_t;
        observed: boolean;
    end record FROn_Ringlet_t;
    type FROnReads_t is array(0 to 80) of FROnRead_t;
    type FROnWrites_t is array(0 to 80) of FROnWrite_t;
    type FRONRinglets_t is array(0 to 80) of FROn_Ringlet_t;
    type FROnDemands_t is array(0 to 80) of std_logic_vector(1 downto 0);
    type FROn_RelayOns_t is array(0 to 80) of std_logic;
    type FROn_CurrentStates_t is array(0 to 80) of std_logic_vector(1 downto 0);
    type FROn_Previousringlets_t is array(0 to 80) of std_logic_vector(1 downto 0);
    type FROn_Resets_t is array(0 to 80) of std_logic;
    
    signal frOnDemands: FROnDemands_t;
    signal frOnRelays: FROn_RelayOns_t;
    signal frOnCurrentStates: FROn_CurrentStates_t;
    signal frOnPreviousRinglets: FROn_PreviousRinglets_t;
    signal frOnResets: FROn_Resets_t := (others => '0');
    
    signal clk: std_logic := '0';
    signal reset: std_logic := '0';
    
    type States_t is array(0 to 728) of std_logic_vector(1 downto 0);
    type Heats_t is array(0 to 728) of std_logic;
    type stdLogicTypes_t is array(0 to 8) of std_logic;
    constant stdLogicTypes: stdLogicTypes_t := (
        0 => 'U',
        1 => 'X',
        2 => '0',
        3 => '1',
        4 => 'Z',
        5 => 'W',
        6 => 'L',
        7 => 'H',
        8 => '-'
    );
    signal internalState: std_logic_vector(2 downto 0);
    
    component FurnaceRelay is
        port(
            clk: in std_logic;
            EXTERNAL_demand: in std_logic_vector(1 downto 0);
            EXTERNAL_Heat: in std_logic := '0';
            EXTERNAL_RelayOn: out std_logic := '0';
            FurnaceRelay_currentState: out std_logic_vector(1 downto 0);
            FurnaceRelay_previousRinglet: out std_logic_vector(1 downto 0);
            FurnaceRelay_internalState: out std_logic_vector(2 downto 0);
            reset: in std_logic
        );
    end component;
    
    signal counter: natural := 0;
    signal counterReset: std_logic := '1';

begin

    -- 1619 states vs >4,782,969 states. 2954.27 order reduction.

    initial_gen: FurnaceRelay port map(
        clk => clk,
        EXTERNAL_demand => "ZZ",
        EXTERNAL_Heat => open,
        EXTERNAL_RelayOn => open,
        FurnaceRelay_currentState => initialCurrentState,
        FurnaceRelay_previousRinglet => initialPreviousRinglet,
        FurnaceRelay_internalState => initialInternalState,
        reset => reset
    );
    
    froff_gen: for i in 0 to 728 generate
        froff_elem: FurnaceRelay port map(
            clk => clk,
            EXTERNAL_demand => frOff_demands(i),
            EXTERNAL_Heat => frOff_heats(i),
            EXTERNAL_RelayOn => frOff_relayOns(i),
            FurnaceRelay_currentState => frOffCurrentStates(i),
            FurnaceRelay_previousRinglet => frOffPreviousRinglets(i),
            FurnaceRelay_internalState => frOffInternalState,
            reset => frOffResets(i)
        );
    end generate froff_gen;
    
    fron_gen: for i in 0 to 80 generate
        fron_elem: FurnaceRelay port map (
            clk => clk,
            EXTERNAL_demand => frOnDemands(i),
            EXTERNAL_Heat => open,
            EXTERNAL_RelayOn => frOnRelays(i),
            FurnaceRelay_currentState => frOnCurrentStates(i),
            FurnaceRelay_previousringlet => frOnPreviousRinglets(i),
            FurnaceRelay_internalState => internalState,
            reset => frOnResets(i)
        );
    end generate fron_gen;

clk <= not clk after 10 ns;

counter <= initialCounter;

initial_proc: process(clk)
variable counterCarry: natural := 0;
begin
if (rising_edge(clk)) then
    if not initialIsInitialised then
        initialIsInitialised <= true;
        reset <= '1';
    else
        -- ReadSnapshot
        if initialInternalState = "101" and initialCurrentState = "00" and initialPreviousRinglet /= "00" then
            if initialReads(0).observed = false then
                initialReads(0) <= (executeOnEntry => initialReads(0).executeOnEntry, observed => true);
                counterCarry := counterCarry + 1;
            end if;
        -- ReadSnapshot on FROff.
        elsif initialInternalState = "101" and initialCurrentState = "01" then
            if initialWrites(0).observed = true then
                for i in 0 to 8 loop
                    for j in 0 to 8 loop
                        for k in 0 to 8 loop
                            if initialFROffEdges(i * 81 + j * 9 + k).observed = false then
                                initialFROffEdges(i * 81 + j * 9 + k) <= (
                                    fromExecuteOnEntry => initialWrites(0).executeOnEntry,
                                    toState => (
                                        EXTERNAL_demand => (1 => stdLogicTypes(i), 0 => stdLogicTypes(j)),
                                        EXTERNAL_Heat => stdLogicTypes(k)
                                    ),
                                    observed => true
                                );
                                if frOffReads(i * 81 + j * 9 + k).observed = false then
                                    frOffReads(i * 81 + j * 9 + k) <= (
                                        executeOnEntry => true,
                                        values => (
                                            EXTERNAL_demand => (1 => stdLogicTypes(i), 0 => stdLogicTypes(j)),
                                            EXTERNAL_Heat => stdLogicTypes(k)
                                        ),
                                        observed => true
                                    );
                                    counterCarry := counterCarry + 1;
                                end if;
                            end if;
                        end loop;
                    end loop;
                end loop;
            end if;
            reset <= '0';
        -- ReadSnapshot on FROn.
        elsif initialInternalState = "101" and initialCurrentState = "10" then
            if initialWrites(0).observed = true then
                for j in 0 to 8 loop
                    for k in 0 to 8 loop
                        if initialFROnEdges(j * 9 + k).observed = false then
                            initialFROnEdges(j * 9 + k) <= (
                                fromExecuteOnEntry => initialWrites(0).executeOnEntry,
                                toState => (
                                    EXTERNAL_demand => (1 => stdLogicTypes(j), 0 => stdLogicTypes(k))
                                ),
                                observed => true
                            );
                            counterCarry := counterCarry + 1;
                        end if;
                    end loop;
                end loop;
            end if;
            reset <= '0';
        elsif initialInternalState = "101" and initialCurrentState = "00" then
            if initialWrites(0).observed = true then
                if initialInitialEdges(0).observed = false then
                    initialInitialEdges(0) <= (fromExecuteOnEntry => initialWrites(0).executeOnEntry, observed => true);
                    counterCarry := counterCarry + 1;
                end if;
            end if;
            reset <= '0';
        -- WriteSnapshot
        elsif initialInternalState = "110" then
            initialRinglets(0) <= (
                read => initialReads(0),
                write => (executeOnEntry => initialReads(0).executeOnEntry, observed => true),
                observed => true
            );
            initialWrites(0) <= (executeOnEntry => initialReads(0).executeOnEntry, observed => true);
        end if;
    end if;
    initialCounter <= counterCarry;
end if;
end process initial_proc;

froff_proc: process(clk)
variable counterCarry: natural := 0;
variable index: integer;
begin
if rising_edge(clk) then
    for i in 0 to 8 loop
        for j in 0 to 8 loop
            for k in 0 to 8 loop
                index := i * 81 + j * 9 + k;
                if frOffInternalState = "101" and frOffCurrentStates(index) = "10" then
                
                elsif frOffInternalState = "101" and frOffCurrentStates(index) = "01" then
                
                elsif frOffInternalState = "101" and frOffCurrentStates(index) = "00" then
                
                elsif frOffInternalState = "110" then
                    frOffRinglets(index) <= (
                        read => frOffReads(index),
                        write => (
                            executeOnEntry => frOffReads(index).executeOnEntry,
                            values => (EXTERNAL_RelayOn => frOff_RelayOns(index)),
                            observed => true
                        ),
                        observed => true
                    );
                end if;
            end loop;
        end loop;
    end loop;
end if;
end process froff_proc;

end Behavioral;
