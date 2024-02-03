defmodule Grp do
	def grpmsgs(remainder, grpdlist, last) do
		#IO.inspect({remainder, grpdlist})
		#IO.puts "\n\n\n\n\n\n\n"
		if remainder == [] do
			grpdlist # return a val
		else
			[curr|remainder] = remainder
			if curr.userid == last.userid do
				grpdlistlast = List.last(grpdlist) ++ [curr]
				grpdlist = grpdlist
						|> List.replace_at(-1, grpdlistlast)
				Grp.grpmsgs(remainder, grpdlist, curr)
			else
				Grp.grpmsgs(remainder, grpdlist++[[curr]], curr)
			end
		end
		# IO.inspect Enum.take_while(remainder, fn m->m.userid==msg.userid end)
		# [_curr| remainder] = remainder
		# IO.inspect(remainder)
	end
end

msgs = [
		%{userid: 1, v: "negawatt1"},
		%{userid: 1, v: "negawatt2"},
		%{userid: 1, v: "negawatt3"},
		%{userid: 2, v: "negasecond1"},
		%{userid: 1, v: "negawatt4"},
		%{userid: 2, v: "negasecond2"},
]

[msg| msgs] = msgs

IO.inspect Grp.grpmsgs(msgs, [[msg]], msg)
