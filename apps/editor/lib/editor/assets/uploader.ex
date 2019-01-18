defmodule Editor.Assets.Uploader do
  alias ExAws.S3

  @bucket_name "marrow-editor"

  def upload(asset_type, {filename, tmp_file_path}) do
    hashed_filename = hash_filename(filename)
    s3_path = path(asset_type, hashed_filename)

    upload =
      tmp_file_path
      |> S3.Upload.stream_file()
      |> S3.upload(@bucket_name, s3_path)

    with {:ok, _} <- ExAws.request(upload) do
      {:ok, filename, hashed_filename, s3_url(s3_path)}
    end
  end

  defp hash_filename(filename) do
    uuid = UUID.uuid4(:hex)
    extension = String.slice(filename, -3, 3)
    "#{uuid}.#{extension}"
  end

  defp path(:image, filename) do
    "images/#{filename}"
  end

  defp path(:audio, filename) do
    "audio/#{filename}"
  end

  defp s3_url(path) do
    "https://s3.eu-west-2.amazonaws.com/#{@bucket_name}/#{path}"
  end

  def delete(asset_type, filename) do
    path = path(asset_type, filename)

    case S3.delete_object(@bucket_name, path) |> ExAws.request() do
      {:ok, _} -> {:ok, :deleted}
      {:error, _} -> {:error, :invalid_request}
    end
  end
end
