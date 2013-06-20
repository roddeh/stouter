http = require("http")
url = require("url")
fs = require("fs")
path = require("path")

onRequest = (request, response) ->
  pathname = url.parse(request.url).pathname
  response.writeHead(200, {"Content-Type": "text/plain"})

  fs.stat(projectPath + config.base + pathname, (err, stat) ->
    if(!err and stat.isFile())
      respondWithFile(pathname, response)
    else
      if(!err)
        fs.exists(projectPath + config.base + pathname + "/" + config.indexFile, (err, file) ->
          if(err)
            respondWithFile(pathname + "/" + config.indexFile, response)
          else
            checkRoutes(pathname, response)
        )
      else
        checkRoutes(pathname, response)
  )

respondWithFile = (filePath, response) ->
  fs.readFile(projectPath + config.base + filePath, "binary", (err, file) ->
    if (err)
      response.writeHead(500, {"Content-Type": "text/plain"})
      response.write(err + "\n")
      response.end()
      return
    fileExtension = filePath.substr(filePath.lastIndexOf(".") + 1)
    mimeType = config.mimeTypes[fileExtension]
    response.writeHead(200, {"Content-Type": mimeType}) if mimeType?
    response.write(file, "binary")
    response.end()
  )  

checkRoutes = (pathname, response) ->
  for r, f of config.routes
    if matchRoute(r, pathname)
      respondWithFile(f, response) 
      return
  respond404(response)

matchRoute = (route, pathname) ->
  return true if route is pathname
  if(route.indexOf("*") != -1)
    return true if pathname.indexOf(route.split("*")[0]) == 0
  return false

respond404 = (response) ->
  response.writeHead(404, {"Content-Type": "text/plain"});
  response.write("404 Not Found\n");
  response.end();

projectPath = process.argv[2] || "./"

try
  config = JSON.parse(fs.readFileSync(projectPath + "stouter_config.json", "utf8"))
catch e
  console.log("Failed to load stouter_config.json")
  console.log("For more info on config files see https://github.com/roddeh/stouter")
  console.log(e.message)
  process.exit(1)

http.createServer(onRequest).listen(config.port)

console.log("---------------------------")
console.log("Started Stouter on port #{config.port}")
console.log("---------------------------")