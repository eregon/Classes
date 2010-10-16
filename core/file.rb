class File
  def File.replace__by_space(path)
    File.rename(path, File.dirname(path)+'/'+File.basename(path, File.extname(path)).gsub(/_/, ' ')+File.extname(path))
  end
end
