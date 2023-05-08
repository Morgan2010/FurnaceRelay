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

    component FurnaceRelayRingletRunner is
    port(
        clk: in std_logic;
        reset: in std_logic := '0';
        state: in std_logic_vector(1 downto 0);
        demand: in std_logic_vector(1 downto 0);
        heat: in std_logic;
        previousRinglet: in std_logic_vector(1 downto 0);
        readSnapshotState: out ReadSnapshot_t;
        writeSnapshotState: out WriteSnapshot_t;
        nextState: out std_logic_vector(1 downto 0);
        finished: out boolean
    );
    end component;
    
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
    signal previousRinglets: std_logic_vector(1 downto 0);
    
    signal maxIndex: integer range 0 to 728;
    signal initialRingletIndex: integer range 0 to 2;
    signal frOffRingletIndex: integer range 0 to 1458;
    signal frOnRingletIndex: integer range 0 to 162;
    
    function boolToStdLogic(value: boolean) return std_logic_vector is
    begin
        if value then
            return "1";
        else
            return "0";
        end if;
    end function;
    
    function pendingIndex(nextState: std_logic_vector(1 downto 0); executeOnEntry: boolean) return std_logic_vector is
    begin
        return nextState & boolToStdLogic(value => executeOnEntry);
    end function;
    
    function pendingIndexInteger(nextState: std_logic_vector(1 downto 0); executeOnEntry: boolean) return integer is
    begin
        return to_integer(unsigned(pendingIndex(nextState => nextState, executeOnEntry => executeOnEntry)));
    end function;
    
begin

run_gen: for i in 0 to 728 generate
    run_inst: FurnaceRelayRingletRunner port map(
        clk => clk,
        reset => reset,
        state => states,
        demand => demands(i),
        heat => heats(i),
        previousRinglet => previousRinglets,
        readSnapshotState => runners(i).readSnapshotState,
        writeSnapshotState => runners(i).writeSnapshotState,
        nextState => runners(i).nextState,
        finished => runners(i).finished
    );
end generate run_gen;

process(clk)
begin
if rising_edge(clk) then
    case genTracker is
        when Setup =>
            pendingStates(pendingIndexInteger(nextState => STATE_Initial, executeOnEntry => true)) <= (
                state => STATE_Initial,
                executeOnEntry => true,
                observed => true
            );
            initialRingletIndex <= 0;
            frOffRingletIndex <= 0;
            frOnRingletIndex <= 0;
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
            for i in 0 to 728 loop
                if i <= maxIndex then
                    allPendingStates(pendingIndexInteger(nextState => runners(i).nextState, executeOnEntry => runners(i).writeSnapshotState.executeOnEntry)) <= (
                        state => runners(i).nextState, executeOnEntry => runners(i).writeSnapshotState.executeOnEntry, observed => true
                    );
                    case states is
                        when STATE_Initial =>
                            initialRinglets(initialRingletIndex + i) <= (
                                readSnapshot => (
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry
                                ),
                                writeSnapshot => (
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry
                                ),
                                observed => true
                            );
                        when STATE_FROff =>
                            frOffRinglets(frOffRingletIndex + i) <= (
                                readSnapshot => (
                                    demand => runners(i).readSnapshotState.demand,
                                    heat => runners(i).readSnapshotState.heat,
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry
                                ),
                                writeSnapshot => (
                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry
                                ),
                                observed => true
                            );
                        when STATE_FROn =>
                            frOnRinglets(frOnRingletIndex + i) <= (
                                readSnapshot => (
                                    demand => runners(i).readSnapshotState.demand,
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry
                                ),
                                writeSnapshot => (
                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry
                                ),
                                observed => true
                            );
                        when others =>
                            null;
                    end case;
                end if;
            end loop;
            case states is
                when STATE_Initial =>
                    initialRingletIndex <= maxIndex + 1;
                when STATE_FROff =>
                    frOffRingletIndex <= maxIndex + 1;
                when STATE_FROn =>
                    frOnRingletIndex <= maxIndex + 1;
                when others =>
                    null;
            end case;
            observedStates(pendingIndexInteger(nextState => states, executeOnEntry => runners(0).readSnapshotState.executeOnEntry)) <= (
                state => states, executeOnEntry => runners(0).readSnapshotState.executeOnEntry, observed => true
            );
            pendingStates(pendingIndexInteger(nextState => states, executeOnEntry => runners(0).readSnapshotState.executeOnEntry)).observed <= false;
            genTracker <= ClearJobs;
        when ClearJobs =>
            reset <= '1';
            for allPendingStatesIndex in 0 to 5 loop
                if allPendingStates(allPendingStatesIndex).observed and not observedStates(allPendingStatesIndex).observed then
                    pendingStates(allPendingStatesIndex) <= allPendingStates(allPendingStatesIndex);
                    allPendingStates(allPendingStatesIndex).observed <= false;
                end if;
            end loop;
            genTracker <= ChooseNextState;
        when ChooseNextState =>
            reset <= '0';
            for s in 0 to 5 loop
                if pendingStates(s).observed then
                    case pendingStates(s).state is
                        when STATE_Initial =>
                            states <= STATE_Initial;
                            maxIndex <= 0;
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
                            maxIndex <= 728;
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
                            maxIndex <= 80;
                            if pendingStates(s).executeOnEntry then
                                previousRinglets <= "ZZ";
                            else
                                previousRinglets <= STATE_FROn;
                            end if;
                        when others =>
                            null;
                    end case;
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

