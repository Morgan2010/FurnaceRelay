----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.05.2023 05:51:12
-- Design Name: 
-- Module Name: KripkeStructureGenerator - Behavioral
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
use work.FurnaceRelayTypes.all;
use work.PrimitiveTypes.all;
use IEEE.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity FurnaceRelayKripkeGenerator is
port(
    clk: in std_logic;
    initialRinglets: out Initial_Ringlets_t;
    frOffRinglets: out FROff_Ringlets_t;
    frOnRinglets: out FROn_Ringlets_t;
    completed: out std_logic := '0'
);
end FurnaceRelayKripkeGenerator;

architecture Behavioral of FurnaceRelayKripkeGenerator is
    signal reset: std_logic;
    signal runners: Runners_t;
    
    constant Setup: std_logic_vector(3 downto 0) := "0000";
    constant StartExecuting: std_logic_vector(3 downto 0) := "0001";
    constant WaitUntilFinish: std_logic_vector(3 downto 0) := "0010";
    constant UpdateKripkeStates: std_logic_vector(3 downto 0) := "0011";
    constant WaitUntilStart: std_logic_vector(3 downto 0) := "0100";
    constant ChooseNextState: std_logic_vector(3 downto 0) := "0101";
    constant ClearJobs: std_logic_vector(3 downto 0) := "0110";
    constant Finished: std_logic_vector(3 downto 0) := "0111";
    constant WaitForRunnerInitialisation: std_logic_vector(3 downto 0) := "1000";
    
    signal genTracker: std_logic_vector(3 downto 0) := Setup;

    signal observedStates: AllStates_t;
    signal pendingStates: AllStates_t;
    signal allPendingStates: AllStates_t;
    signal states: std_logic_vector(1 downto 0);
    signal demands: Demands_t;
    signal heats: Heats_t;
    signal relayOns: Heats_t;
    signal previousRinglets: std_logic_vector(1 downto 0);

    signal initialRinglet: Initial_Ringlet_t;
    signal initialPendingState: ObservedState_t;
    
    signal frOffRingletAcc: FROff_Ringlets_t;
    signal frOffPendingStates: FROFF_States_t;
    
    signal frOnRingletAcc: FROn_Ringlets_t;
    signal frOnPendingStates: FROn_States_t;
    
    function boolToStdLogic(value: boolean) return std_logic_vector is
    begin
        if value then
            return "1";
        else
            return "0";
        end if;
    end function;
    
    function stdLogicToInteger(value: std_logic) return integer is
    begin
        case value is
            when 'U' =>
                return 0;
            when 'X' =>
                return 1;
            when '0' =>
                return 2;
            when '1' =>
                return 3;
            when 'Z' =>
                return 4;
            when 'W' =>
                return 5;
            when 'L' =>
                return 6;
            when 'H' =>
                return 7;
            when '-' =>
                return 8;
        end case;
    end function;
    
    function pendingIndex(nextState: std_logic_vector(1 downto 0); relayOn: std_logic; executeOnEntry: boolean) return std_logic_vector is
    begin
        return std_logic_vector(to_unsigned(stdLogicToInteger(value => relayOn), 4)) & nextState & boolToStdLogic(value => executeOnEntry);
    end function;
    
    function pendingIndexInteger(nextState: std_logic_vector(1 downto 0); relayOn: std_logic; executeOnEntry: boolean) return integer is
    begin
        return to_integer(unsigned(pendingIndex(nextState => nextState, relayOn => relayOn, executeOnEntry => executeOnEntry)));
    end function;
    
    function pendingIndexFromObserved(observed: ObservedState_t) return integer is
    begin
        return pendingIndexInteger(nextState => observed.state, relayOn => observed.fr_relayOn, executeOnEntry => observed.executeOnEntry);
    end function;
    
    component FurnaceRelayRingletRunner is
    port(
        clk: in std_logic;
        reset: in std_logic := '0';
        state: in std_logic_vector(1 downto 0);
        demand: in std_logic_vector(1 downto 0);
        heat: in std_logic;
        relayOn: in std_logic;
        previousRinglet: in std_logic_vector(1 downto 0);
        readSnapshotState: out ReadSnapshot_t;
        writeSnapshotState: out WriteSnapshot_t;
        nextState: out std_logic_vector(1 downto 0);
        finished: out boolean
    );
    end component;
    
    component InitialKripkeGenerator is
    port(
        clk: in std_logic;
        readSnapshot: in ReadSnapshot_t;
        writeSnapshot: in WriteSnapshot_t;
        ringlet: out Initial_Ringlet_t;
        pendingState: out ObservedState_t
    );
    end component;
    
    component FROffKripkeGenerator is
    port(
        clk: in std_logic;
        readSnapshot: in ReadSnapshot_t;
        writeSnapshot: in WriteSnapshot_t;
        ringlet: out FROff_Ringlet_t;
        pendingState: out ObservedState_t
    );
    end component;
    
    component FROnKripkeGenerator is
    port(
        clk: in std_logic;
        readSnapshot: in ReadSnapshot_t;
        writeSnapshot: in WriteSnapshot_t;
        ringlet: out FROn_Ringlet_t;
        pendingState: out ObservedState_t
    );
    end component;
    
begin

run_gen: for i in 0 to 728 generate
    run_inst: FurnaceRelayRingletRunner port map(
        clk => clk,
        reset => reset,
        state => states,
        demand => demands(i),
        heat => heats(i),
        relayOn => relayOns(i),
        previousRinglet => previousRinglets,
        readSnapshotState => runners(i).readSnapshotState,
        writeSnapshotState => runners(i).writeSnapshotState,
        nextState => runners(i).nextState,
        finished => runners(i).finished
    );
end generate run_gen;

init_gen: InitialKripkeGenerator port map(
    clk => clk,
    readSnapshot => runners(0).readSnapshotState,
    writeSnapshot => runners(0).writesnapshotState,
    ringlet => initialRinglet,
    pendingState => initialPendingState
);

froff_gen: for i in 0 to 728 generate
    froff_inst: FROffKripkeGenerator port map(
        clk => clk,
        readSnapshot => runners(i).readSnapshotState,
        writeSnapshot => runners(i).writeSnapshotState,
        ringlet => frOffRingletAcc(i),
        pendingState => frOffPendingStates(i)
    );
end generate froff_gen;

fron_gen: for i in 0 to 80 generate
    fron_inst: FROnKripkeGenerator port map(
        clk => clk,
        readSnapshot => runners(i).readSnapshotState,
        writeSnapshot => runners(i).writeSnapshotState,
        ringlet => frOnRingletAcc(i),
        pendingState => frOnPendingStates(i)
    );
end generate fron_gen;

process(clk)
begin
if rising_edge(clk) then
    case genTracker is
        when Setup =>
            pendingStates(pendingIndexInteger(nextState => STATE_Initial, relayOn => 'U', executeOnEntry => true)) <= (
                state => STATE_Initial,
                fr_relayOn => 'U',
                executeOnEntry => true,
                observed => true
            );
            genTracker <= ChooseNextState;
            reset <= '0';
        when StartExecuting =>
            reset <= '1';
            genTracker <= WaitUntilStart;
        when WaitUntilStart =>
            reset <= '1';
            genTracker <= WaitUntilFinish;
        when WaitUntilFinish =>
            reset <= '1';
            if runners(0).finished then
                genTracker <= UpdateKripkeStates;
            end if;
        when UpdateKripkeStates =>
            reset <= '1';
            case states is
                when STATE_Initial =>
                    if initialRinglet.readSnapshot.executeOnEntry then
                        initialRinglets(0) <= initialRinglet;
                    else
                        initialRinglets(1) <= initialRinglet;
                    end if;
                    allPendingStates(pendingIndexInteger(nextState => initialRinglet.writeSnapshot.nextState, relayOn => initialRinglet.writeSnapshot.fr_relayOn, executeOnEntry => initialRinglet.writeSnapshot.executeOnEntry)) <= initialPendingState;
                when STATE_FROff =>
                    if frOffRingletAcc(0).readSnapshot.executeOnEntry then
                        frOffRinglets(0 to 728) <= frOffRingletAcc(0 to 728);
                    else
                        frOffRinglets(729 to 1457) <= frOffRingletAcc(0 to 728);
                    end if;
                    for i in 0 to 728 loop
                        allPendingStates(pendingIndexFromObserved(observed => frOffPendingStates(i))) <= frOffPendingStates(i);
                    end loop;
                when STATE_FROn =>
                    if frOnRingletAcc(0).readSnapshot.executeOnEntry then
                        frOnRinglets(0 to 80) <= frOnRingletAcc(0 to 80);
                    else
                        frOnRinglets(81 to 161) <= frOnRingletAcc(0 to 80);
                    end if;
                    for i in 0 to 80 loop
                        allPendingStates(pendingIndexFromObserved(observed => frOnPendingStates(i))) <= frOnPendingStates(i);
                    end loop;
                when others =>
                    null;
            end case;
            observedStates(pendingIndexInteger(nextState => states, relayOn => runners(0).readSnapshotState.fr_relayOn, executeOnEntry => runners(0).readSnapshotState.executeOnEntry)) <= (
                state => states, fr_relayOn => runners(0).readSnapshotState.fr_relayOn, executeOnEntry => runners(0).readSnapshotState.executeOnEntry, observed => true
            );
            pendingStates(pendingIndexInteger(nextState => states, relayOn => runners(0).readSnapshotState.fr_relayOn, executeOnEntry => runners(0).readSnapshotState.executeOnEntry)).observed <= false;
            genTracker <= ClearJobs;
        when ClearJobs =>
            reset <= '1';
            for allPendingStatesIndex in 0 to 53 loop
                if allPendingStates(allPendingStatesIndex).observed and not observedStates(allPendingStatesIndex).observed then
                    pendingStates(allPendingStatesIndex) <= allPendingStates(allPendingStatesIndex);
                    allPendingStates(allPendingStatesIndex).observed <= false;
                end if;
            end loop;
            genTracker <= ChooseNextState;
        when ChooseNextState =>
            reset <= '0';
            for s in 0 to 53 loop
                if pendingStates(s).observed then
                    case pendingStates(s).state is
                        when STATE_Initial =>
                            states <= STATE_Initial;
                            if pendingStates(s).executeOnEntry then
                                previousRinglets <= "ZZ";
                            else
                                previousRinglets <= STATE_Initial;
                            end if;
                        when STATE_FROff =>
                            for i in 0 to 8 loop
                                for j in 0 to 8 loop
                                    for k in 0 to 8 loop
                                        demands(i * 81 + j * 9 + k) <= (1 => stdLogicTypes(i), 0 => stdLogicTypes(j));
                                        heats(i * 81 + j * 9 + k) <= stdLogicTypes(k);
                                    end loop;
                                end loop;
                            end loop;
                            states <= STATE_FROff;
                            if pendingStates(s).executeOnEntry then
                                previousRinglets <= "ZZ";
                            else
                                previousRinglets <= STATE_FROff;
                            end if;
                        when STATE_FROn =>
                            for i in 0 to 8 loop
                                for j in 0 to 8 loop
                                    demands(i * 9 + j) <= (1 => stdLogicTypes(i), 0 => stdLogicTypes(j));
                                end loop;
                            end loop;
                            states <= STATE_FROn;
                            if pendingStates(s).executeOnEntry then
                                previousRinglets <= "ZZ";
                            else
                                previousRinglets <= STATE_FROn;
                            end if;
                        when others =>
                            null;
                    end case;
                    relayOns <= (others => pendingStates(s).fr_relayOn);
                    genTracker <= WaitForRunnerInitialisation;
                    exit;
                elsif s = 5 then
                    genTracker <= Finished;
                end if;
            end loop;
        when WaitForRunnerInitialisation =>
            reset <= '0';
            genTracker <= StartExecuting;
        when Finished =>
            completed <= '1';
        when others =>
            null;
    end case;
end if;
end process;

end Behavioral;

