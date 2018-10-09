defmodule IEx.Filter do

  def start(shell) do
    spawn_link(fn ->
      port = Port.open({:spawn, :"tty_sl -c -e"}, [:eof])
      driver = :user_drv.start(self(), shell)
      loop({port, driver})
    end)
  end


  defp loop({port, driver} = state) do
    receive do
      {^driver, msg}  ->
        send(port, {self(), msg})
        # :erlang.display_string('>> From driver: #{inspect msg}\n')

      {^port, {:data, '\e[1~'}} ->
        send(driver, {self(), {:data, [1]}})

      {^port, {:data, '\e[4~'}} ->
        send(driver, {self(), {:data, [5]}})

      {^port, {:data, '\f'} = msg} ->
        cmd = [0 | [IO.ANSI.clear(), IO.ANSI.home()]]
        send(port, {self(), {:command, cmd}})
        send(driver, {self(), msg})

      {^port, msg}    ->
        send(driver, {self(), msg})
        # :erlang.display_string('>> From port: #{inspect msg}\n')
    end
    loop(state)
  end
end
