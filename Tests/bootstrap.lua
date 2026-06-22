local root = os.getenv("PTS_ROOT") or "."
root = root:gsub("\\", "/")
if root:sub(-1) == "/" then
	root = root:sub(1, -2)
end
package.path = root
	.. "/?.lua;"
	.. root
	.. "/?/init.lua;"
	.. root
	.. "/Tests/?.lua;"
	.. root
	.. "/Tests/?/init.lua;"
	.. package.path
