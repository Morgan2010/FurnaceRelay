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
    signal reset: std_logic := '0';
    signal runners: Runners_t;

    component FurnaceRelayRingletRunner is
    port(
        clk: in std_logic;
        reset: in std_logic := '0';
        state: in std_logic_vector(1 downto 0) := "00";
        demand: in std_logic_vector(1 downto 0) := "00";
        heat: in std_logic := '0';
        previousRinglet: in std_logic_vector(1 downto 0) := "ZZ";
        readSnapshotState: out ReadSnapshot_t;
        writeSnapshotState: out WriteSnapshot_t;
        nextState: out std_logic_vector(1 downto 0);
        finished: out boolean := true
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
    signal states: std_logic_vector(1 downto 0);
    signal demands: Demands_t;
    signal heats: Heats_t;
    signal previousRinglets: std_logic_vector(1 downto 0);
    
    signal maxIndex: integer range 0 to 728;
    signal initialRingletIndex: integer range 0 to 2;
    signal frOffRingletIndex: integer range 0 to 1458 := 0;
    signal frOnRingletIndex: integer range 0 to 162 := 0;
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
variable observedStatesIndex: integer range 0 to 6 := 0;
variable pendingStatesIndex: integer range 0 to 6 := 0;
begin
if rising_edge(clk) then
    case genTracker is
        when Setup =>
            pendingStates(0) <= (
                state => STATE_Initial,
                executeOnEntry => true,
                observed => true
            );
            initialRingletIndex <= 0;
            frOffRingletIndex <= 0;
            frOnRingletIndex <= 0;
            genTracker <= ChooseNextState;
        when StartExecuting =>
            reset <= '1';
            genTracker <= WaitUntilStart;
        when WaitUntilStart =>
            reset <= '1';
            genTracker <= WaitUntilFinish;
        when WaitUntilFinish =>
            reset <= '1';
            for i in 0 to maxIndex loop
                if runners(i).finished then
                    genTracker <= UpdateKripkeStates;
                    exit;
                end if;
            end loop;
        when UpdateKripkeStates =>
            reset <= '1';
            for i in 0 to maxIndex loop
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
                -- When i=0, Check existing saved snapshots before writing new snapshot into buffer.
                if i = 0 then
                    for os in 0 to 5 loop
                        if observedStates(os).observed and observedStates(os).state = states and observedStates(os).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                            exit;
                        elsif os >= observedStatesIndex and not observedStates(os).observed then
                            observedStates(os) <= (state => states, executeOnEntry => runners(i).readSnapshotState.executeOnEntry, observed => true);
                            observedStatesIndex := os + 1;
                            exit;
                        end if;
                    end loop;
                    -- Check if next state is not the same as the state that was just executed.
                    if not (runners(i).nextState = states and runners(i).writeSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                        -- Add to pending states logic.
                        for ps in 0 to 5 loop
                            -- If already exists in pending state or already exists in observed states, then exit.
                            if (pendingStates(ps).observed and pendingStates(ps).state = runners(i).nextState and pendingStates(ps).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) or
                                (observedStates(ps).observed and observedStates(ps).state = runners(i).nextState and observedStates(ps).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                exit;
                            -- otherwise, add to pending states.
                            elsif ps >= pendingStatesIndex and not pendingStates(ps).observed then
                                pendingStates(ps) <= (
                                    state => runners(i).nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                    observed => true
                                );
                                pendingStatesIndex := ps + 1;
                                exit;
                            end if;
                        end loop;
                    end if;
                else
                    for rsi in 0 to (i - 1) loop
                        if (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                            exit;
                        elsif rsi = i - 1 then
                            for os in 0 to 5 loop
                                if observedStates(os).observed and observedStates(os).state = states and observedStates(os).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                    exit;
                                elsif os >= observedStatesIndex and not observedStates(os).observed then
                                    observedStates(os) <= (state => states, executeOnEntry => runners(i).readSnapshotState.executeOnEntry, observed => true);
                                    observedStatesIndex := os + 1;
                                    exit;
                                end if;
                            end loop;
                        end if;
                    end loop;
                    for rsi in 0 to (i - 1) loop
                        if (runners(rsi).nextState = runners(i).nextState) and ((states /= runners(rsi).nextState) = (states /= runners(i).nextState)) then
                            exit;
                        elsif rsi = i - 1 then
                            -- Check if next state is not the same as the state that was just executed.
                            if not (runners(i).nextState = states and runners(i).writeSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                -- Add to pending states logic.
                                for ps in 0 to 5 loop
                                    -- If already exists in pending state or already exists in observed states, then exit.
                                    if (pendingStates(ps).observed and pendingStates(ps).state = runners(i).nextState and pendingStates(ps).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) or 
                                        (observedStates(ps).observed and observedStates(ps).state = runners(i).nextState and observedStates(ps).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                        exit;
                                    -- otherwise, add to pending states.
                                    elsif ps >= pendingStatesIndex and not pendingStates(ps).observed then
                                        pendingStates(ps) <= (
                                            state => runners(i).nextState,
                                            executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        pendingStatesIndex := ps + 1;
                                        exit;
                                    end if;
                                end loop;
                            end if;
                        end if;
                    end loop;
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
            genTracker <= ClearJobs;
        when ClearJobs =>
            reset <= '1';
            for j in 0 to 5 loop
                for p in 0 to 5 loop
                    if pendingStates(p).observed then
                        if pendingStates(p) = observedStates(j) then
                            pendingStates(p).observed <= false;
                        end if;
                    end if;
                end loop;
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

