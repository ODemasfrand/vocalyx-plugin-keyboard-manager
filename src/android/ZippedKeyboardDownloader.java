package com.capanovi;

import java.io.BufferedInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URL;
import java.net.URLConnection;

public class ZippedKeyboardDownloader{
	private URL url;
	private OutputStream outputStream;

	public ZippedKeyboardDownloader(String keyboardZipName, String urlString, String outputDirectory) throws IOException{
		url = new URL(urlString + "/" + keyboardZipName);
		outputStream = new FileOutputStream(outputDirectory + "/" + keyboardZipName);
	}

	public ZippedKeyboardDownloader download() throws FileNotFoundException, IOException{
		URLConnection urlConnection = url.openConnection();
		urlConnection.connect();

		InputStream inputStream = new BufferedInputStream(url.openStream(), KeyboardsManager.READ_BUFFER_SIZE);
		byte data[] = new byte[KeyboardsManager.READ_BUFFER_SIZE];

		int readBytes;

		while((readBytes = inputStream.read(data)) != -1)
			outputStream.write(data, 0, readBytes);

		outputStream.flush();

		outputStream.close();
		inputStream.close();

		return this;
	}
}
