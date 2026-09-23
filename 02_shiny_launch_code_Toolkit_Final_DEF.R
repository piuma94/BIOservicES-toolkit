#install.packages(c("shinylive", "httpuv")) ## pacchetti per convertire il tutto in html

repo_dir <- "C:/Users/luigi.caopinna/OneDrive - CREA/Documents/GitHub/BIOservicES-toolkit"

shinylive::export(
  appdir = repo_dir,
  destdir = file.path(repo_dir, "docs"),
  wasm_packages = TRUE ## this is to have the possibility of reading R packages in the browser
)

# crea .nojekyll DOPO l'export
file.create(file.path(repo_dir, "docs", ".nojekyll")) # these are some needed file to be read by the github online

# controlli
file.exists(file.path(repo_dir, "docs", "index.html"))
file.exists(file.path(repo_dir, "docs", ".nojekyll"))

# test locale - questa riga blocca R finché non chiudi il server
httpuv::runStaticServer(
  file.path(repo_dir, "docs")
)
