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
    signal initialReadSnapshots: Initial_ReadSnapshots_t;
    signal initialWriteSnapshots: Initial_WriteSnapshots_t;
    signal frOffReadSnapshots: FROff_ReadSnapshots_t;
    signal frOffWriteSnapshots: FROff_WriteSnapshots_t;
    signal frOnReadSnapshots: FROn_Readsnapshots_t;
    signal frOnWriteSnapshots: FROn_WriteSnapshots_t;
    signal reset: std_logic := '0';
    signal runners: Runners_t := (others => (
        readSnapshotState => (
            demand => "00",
            heat => '0',
            state => "00",
            executeOnEntry => true
        ),
        writeSnapshotState => (
            demand => "00",
            heat => '0',
            relayOn => '0',
            state => "00",
            nextState => "00",
            executeOnEntry => false
        ),
        nextState => "00",
        finished => true
    ));
    
    signal currentJobs: CurrentJobs_t := (others => false);

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
    signal states: std_logic_vector(1 downto 0) := STATE_Initial;
    signal demands: Demands_t := (others => "00");
    signal heats: Heats_t := (others => '0');
    signal previousRinglets: std_logic_vector(1 downto 0) := "ZZ";

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
variable initialReadSnapshotIndex: integer range 0 to 2 := 0;
variable initialWriteSnapshotIndex: integer range 0 to 6 := 0;
variable initialRingletIndex: integer range 0 to 2 := 0;
variable frOffReadSnapshotIndex: integer range 0 to 1458 := 0;
variable frOffWriteSnapshotIndex: integer range 0 to 54 := 0;
variable frOffRingletIndex: integer range 0 to 1458 := 0;
variable frOnReadSnapshotIndex: integer range 0 to 162 := 0;
variable frOnWriteSnapshotIndex: integer range 0 to 54 := 0;
variable frOnRingletIndex: integer range 0 to 162 := 0;
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
            genTracker <= ChooseNextState;
        when StartExecuting =>
            reset <= '1';
            genTracker <= WaitUntilStart;
        when WaitUntilStart =>
            reset <= '1';
            genTracker <= WaitUntilFinish;
        when WaitUntilFinish =>
            reset <= '1';
            for i in 0 to 728 loop
                if currentJobs(i) then
                    if runners(i).finished then
                        genTracker <= UpdateKripkeStates;
                    end if;
                end if;
            end loop;
        when UpdateKripkeStates =>
            reset <= '1';
            for i in 0 to 728 loop
                if currentJobs(i) then
                    case states is
                        when STATE_Initial =>
                            initialRinglets(initialRingletIndex) <= (
                                readSnapshot => (
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                writeSnapshot => (
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                observed => true
                            );
                            initialRingletIndex := initialRingletIndex + 1;
                            -- When i=0, Check existing saved snapshots before writing new snapshot into buffer.
                            if i = 0 then
                                for rs in 0 to 1 loop
                                    if (initialReadSnapshots(rs).observed and initialReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rs >= initialReadSnapshotIndex and not initialReadSnapshots(rs).observed then
                                        initialReadSnapshots(rs) <= (
                                            executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        initialReadSnapshotIndex := rs + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ws in 0 to 5 loop
                                    if (initialWriteSnapshots(ws).observed and initialWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry and initialWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState) then
                                        exit;
                                    elsif ws >= initialWriteSnapshotIndex and not initialWriteSnapshots(ws).observed then
                                        initialWriteSnapshots(ws) <= (
                                            nextState => runners(i).writeSnapshotState.nextState,
                                            executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        initialWriteSnapshotIndex := ws + 1;
                                        exit;
                                    end if;
                                end loop;
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
                                -- When i>0, Check all previous current jobs for the same snapshots and the saved snapshots before adding a new entry into the saved snapshot buffers. 
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for rs in 0 to 1 loop
                                            if (initialReadSnapshots(rs).observed and initialReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                                exit;
                                            elsif rs >= initialReadSnapshotIndex and not initialReadSnapshots(rs).observed then
                                                initialReadSnapshots(rs) <= (
                                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                initialReadSnapshotIndex := rs + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).writeSnapshotState.executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) and (runners(rsi).writeSnapshotState.nextState = runners(i).writeSnapshotState.nextState) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for ws in 0 to 5 loop
                                            if (initialWriteSnapshots(ws).observed and initialWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) and initialWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState then
                                                exit;
                                            elsif ws >= initialWriteSnapshotIndex and not initialWriteSnapshots(ws).observed then
                                                initialWriteSnapshots(ws) <= (
                                                    nextState => runners(i).writeSnapshotState.nextState,
                                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                initialWriteSnapshotIndex := ws + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
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
                                    if currentJobs(rsi) and (runners(rsi).nextState = runners(i).nextState) and ((states /= runners(rsi).nextState) = (states /= runners(i).nextState)) then
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
                        when STATE_FROff =>
                            frOffRinglets(frOffRingletIndex) <= (
                                readSnapshot => (
                                    demand => runners(i).readSnapshotState.demand,
                                    heat => runners(i).readSnapshotState.heat,
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                writeSnapshot => (
                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                observed => true
                            );
                            frOffRingletIndex := frOffRingletIndex + 1;
                            if i = 0 then
                                for rs in 0 to 1457 loop
                                    if frOffReadSnapshots(rs).observed and frOffReadSnapshots(rs).demand = runners(i).readSnapshotState.demand and frOffReadSnapshots(rs).heat = runners(i).readSnapshotState.heat and frOffReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                        exit;
                                    elsif rs >= frOffReadSnapshotIndex and not frOffReadSnapshots(rs).observed then
                                        frOffReadSnapshots(rs) <= (
                                            demand => runners(i).readSnapshotState.demand,
                                            heat => runners(i).readSnapshotState.heat,
                                            executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        frOffReadSnapshotIndex := rs + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ws in 0 to 53 loop
                                    if frOffWriteSnapshots(ws).observed and frOffWriteSnapshots(ws).relayOn = runners(i).writeSnapshotState.relayOn and frOffWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState and frOffWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry then
                                        exit;
                                    elsif ws >= frOffWriteSnapshotIndex and not frOffWriteSnapshots(ws).observed then
                                        frOffWriteSnapshots(ws) <= (
                                            relayOn => runners(i).writeSnapshotState.relayOn,
                                            nextState => runners(i).writeSnapshotState.nextState,
                                            executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        frOffWriteSnapshotIndex := ws + 1;
                                        exit;
                                    end if;
                                end loop;
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
                                -- When i>0, Check all previous current jobs for the same snapshots and the saved snapshots before adding a new entry into the saved snapshot buffers. 
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.demand = runners(i).readSnapshotState.demand) and (runners(rsi).readSnapshotState.heat = runners(i).readSnapshotState.heat) and
                                        (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for rs in 0 to 1457 loop
                                            if frOffReadSnapshots(rs).observed and frOffReadSnapshots(rs).demand = runners(i).readSnapshotState.demand and frOffReadSnapshots(rs).heat = runners(i).readSnapshotState.heat and frOffReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                                exit;
                                            elsif rs >= frOffReadSnapshotIndex and not frOffReadSnapshots(rs).observed then
                                                frOffReadSnapshots(rs) <= (
                                                    demand => runners(i).readSnapshotState.demand,
                                                    heat => runners(i).readSnapshotState.heat,
                                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                frOffReadSnapshotIndex := rs + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).writeSnapshotState.relayOn = runners(i).writeSnapshotState.relayOn) and (runners(rsi).writeSnapshotState.nextState = runners(i).writeSnapshotState.nextState) and (runners(rsi).writeSnapshotState.executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for ws in 0 to 53 loop
                                            if frOffWriteSnapshots(ws).observed and frOffWriteSnapshots(ws).relayOn = runners(i).writeSnapshotState.relayOn and frOffWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState and frOffWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry then
                                                exit;
                                            elsif ws >= frOffWriteSnapshotIndex and not frOffWriteSnapshots(ws).observed then
                                                frOffWriteSnapshots(ws) <= (
                                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                                    nextState => runners(i).writeSnapshotState.nextState,
                                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                frOffWriteSnapshotIndex := ws + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
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
                                    if currentJobs(rsi) and (runners(rsi).nextState = runners(i).nextState) and ((states /= runners(rsi).nextState) = (states /= runners(i).nextState)) then
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
                        when STATE_FROn =>
                            frOnRinglets(frOnRingletIndex) <= (
                                readSnapshot => (
                                    demand => runners(i).readSnapshotState.demand,
                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                writeSnapshot => (
                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                    nextState => runners(i).writeSnapshotState.nextState,
                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                    observed => true
                                ),
                                observed => true
                            );
                            frOnRingletIndex := frOnRingletIndex + 1;
                            if i = 0 then
                                for rs in 0 to 161 loop
                                    if frOnReadSnapshots(rs).observed and frOnReadSnapshots(rs).demand = runners(i).readSnapshotState.demand and frOnReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                        exit;
                                    elsif rs >= frOnReadSnapshotIndex and not frOnReadSnapshots(rs).observed then
                                        frOnReadSnapshots(rs) <= (
                                            demand => runners(i).readSnapshotState.demand,
                                            executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        frOnReadSnapshotIndex := rs + 1;
                                        exit;
                                    end if;
                                end loop;
                                for ws in 0 to 53 loop
                                    if frOnWriteSnapshots(ws).observed and frOnWriteSnapshots(ws).relayOn = runners(i).writeSnapshotState.relayOn and frOnWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState and frOnWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry then
                                        exit;
                                    elsif ws >= frOnWriteSnapshotIndex and not frOnWriteSnapshots(ws).observed then
                                        frOnWriteSnapshots(ws) <= (
                                            relayOn => runners(i).writeSnapshotState.relayOn,
                                            nextState => runners(i).writeSnapshotState.nextState,
                                            executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                            observed => true
                                        );
                                        frOnWriteSnapshotIndex := ws + 1;
                                        exit;
                                    end if;
                                end loop;
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
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.demand = runners(i).readSnapshotState.demand) and
                                        (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for rs in 0 to 161 loop
                                            if frOnReadSnapshots(rs).observed and frOnReadSnapshots(rs).demand = runners(i).readSnapshotState.demand and frOnReadSnapshots(rs).executeOnEntry = runners(i).readSnapshotState.executeOnEntry then
                                                exit;
                                            elsif rs >= frOnReadSnapshotIndex and not frOnReadSnapshots(rs).observed then
                                                frOnReadSnapshots(rs) <= (
                                                    demand => runners(i).readSnapshotState.demand,
                                                    executeOnEntry => runners(i).readSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                frOnReadSnapshotIndex := rs + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).writeSnapshotState.relayOn = runners(i).writeSnapshotState.relayOn) and (runners(rsi).writeSnapshotState.nextState = runners(i).writeSnapshotState.nextState) and (runners(rsi).writeSnapshotState.executeOnEntry = runners(i).writeSnapshotState.executeOnEntry) then
                                        exit;
                                    elsif rsi = i - 1 then
                                        for ws in 0 to 53 loop
                                            if frOnWriteSnapshots(ws).observed and frOnWriteSnapshots(ws).relayOn = runners(i).writeSnapshotState.relayOn and frOnWriteSnapshots(ws).nextState = runners(i).writeSnapshotState.nextState and frOnWriteSnapshots(ws).executeOnEntry = runners(i).writeSnapshotState.executeOnEntry then
                                                exit;
                                            elsif ws >= frOnWriteSnapshotIndex and not frOnWriteSnapshots(ws).observed then
                                                frOnWriteSnapshots(ws) <= (
                                                    relayOn => runners(i).writeSnapshotState.relayOn,
                                                    nextState => runners(i).writeSnapshotState.nextState,
                                                    executeOnEntry => runners(i).writeSnapshotState.executeOnEntry,
                                                    observed => true
                                                );
                                                frOnWriteSnapshotIndex := ws + 1;
                                                exit;
                                            end if;
                                        end loop;
                                    end if;
                                end loop;
                                for rsi in 0 to (i - 1) loop
                                    if currentJobs(rsi) and (runners(rsi).readSnapshotState.executeOnEntry = runners(i).readSnapshotState.executeOnEntry) then
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
                                    if currentJobs(rsi) and (runners(rsi).nextState = runners(i).nextState) and ((states /= runners(rsi).nextState) = (states /= runners(i).nextState)) then
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
                        when others =>
                            null;
                    end case;
                end if;
            end loop;
            genTracker <= ClearJobs;
        when ClearJobs =>
            reset <= '1';
            currentJobs <= (others => false);
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
                            currentJobs(0) <= true;
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
                                        
                                        currentJobs(i * 81 + j * 9 + k) <= true;
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
                                    currentJobs(i * 9 + j) <= true;
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

