install.packages(c("shinylive", "httpuv")) ## pacchetti per convertire il tutto in html
shinylive::export(
  appdir = "C:/Users/luigi.caopinna/OneDrive - CREA/Desktop/Documenti summary BIOservicES/Toolkit Final DEF - online trial",
  destdir = "docs",
  wasm_packages = TRUE
) ### esportiamo la shiny in html ora quindi 

httpuv::runStaticServer("docs")
# create the .nojekyll file 
file.create("docs/.nojekyll")
# does the files exist
file.exists("docs/index.html")
file.exists("docs/.nojekyll")
