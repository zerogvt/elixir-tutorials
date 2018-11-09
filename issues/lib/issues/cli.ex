defmodule Issues.CLI do
@default_count 4
@moduledoc """
Handle the command line parsing and the dispatch to
the various functions that end up generating a
table of the last _n_ issues in a github project
"""
def run(argv) do
  argv
  |> parse_args
  |> process
end


def process(:help) do
  IO.puts "usage: issues <user> <project> [ count | #{@default_count} ]"
end

def process({user, project, count}) do
  Issues.GithubIssues.fetch(user, project)
  |> decode_response()
  |> sort_into_descending_order()
  |> last(count)
  |> print_table_cols(["number", "created_at", "title"])
end

def my_print_table_cols(list_of_issues, fields) do
  list_of_issues
  |> Enum.map(fn issue -> {issue["number"], issue["created_at"], issue["title"]} end)
  |> Enum.map( &( printable(elem(&1,0)) <> " | " <> printable(elem(&1,1)) <> " | " <> printable(elem(&1,2)) <> "\n") )
  |> IO.puts()
end

def print_table_cols(list_of_issues, headers) do
  with data_by_cols = split_into_cols(list_of_issues, headers),
       col_widths = widths_of(data_by_cols),
       format = format_for(col_widths)
  do
    puts_one_line_in_columns(headers, format)
    IO.puts(separator(col_widths))
    puts_in_columns(data_by_cols, format)
  end
end

def format_for(col_widths) do
  Enum.map_join(col_widths, "|", fn width -> "~-#{width}s" end) <> "~n"
end

def separator(col_widths) do
  Enum.map_join(col_widths, "+", fn width -> List.duplicate("-", width) end)
end

def puts_one_line_in_columns(fields, format) do
  :io.format(format, fields)
end

def puts_in_columns(data_by_cols, format) do
  data_by_cols
  |> List.zip
  |> Enum.map(&Tuple.to_list/1)
  |> Enum.each(&(:io.format(format, &1)))
end

def split_into_cols(rows, headers) do
  for header <- headers do
    for row <- rows, do: printable(row[header])
  end
end

def widths_of(columns) do
  for col <- columns, do: col |> Enum.map(&String.length/1) |> Enum.max
end

def printable(str) when is_binary(str), do: Kernel.inspect(str)
def printable(str), do: to_string(str)

def max_string(list_of_issues, field) do
  list_of_issues
  |> Enum.map(fn issue -> String.length(Kernel.inspect(issue[field])) end)
  |> IO.inspect(charlists: :as_lists)
  |> Enum.max()
end

def last(list, count) do
  list
  |> Enum.take(count)
  |> Enum.reverse
end

def sort_into_descending_order(list_of_issues) do
  list_of_issues
  |> Enum.sort(fn issue_1, issue_2 ->
                issue_1["created_at"] >= issue_2["created_at"]
              end)
end

def decode_response({:ok, body}), do: body
def decode_response({:error, error}) do
  IO.puts "Error fetching from GH: #{error["message"]}"
  System.halt(2)
end

@doc """
`argv` can be -h or --help, which returns :help.
Otherwise it is a github user name, project name, and (optionally)
the number of entries to format.
Return a tuple of `{ user, project, count }`, or `:help` if help was given.
"""
def parse_args(argv) do
  parse = OptionParser.parse(argv,
                             switches: [help: :boolean],
                             aliases: [ h: :help ])
  |> elem(1)
  |> args_to_internal_representation()
end

def args_to_internal_representation([user, project, count]) do
  { user, project, String.to_integer(count) }
end

def args_to_internal_representation([user, project]) do
  { user, project, @default_count }
end

def args_to_internal_representation(_) do
  :help
end

end
