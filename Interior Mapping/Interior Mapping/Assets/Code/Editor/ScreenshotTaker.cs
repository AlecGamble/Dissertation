using UnityEngine;
using UnityEditor;

public class ScreenshotTaker
{
	[MenuItem("Screen/Capture Map")]
	public static void CaptureMap()
	{
		string date = System.DateTime.Now.ToString();
		date = date.Replace("/","-");
		date = date.Replace(" ","_");
		date = date.Replace(":","-");
		ScreenCapture.CaptureScreenshot(Application.dataPath + "/Data/Textures/InteriorMaps/"+date+".png");
	}

	[MenuItem("Screen/Capture Screenshot")]
	public static void CaptureScreenshot()
	{
		string date = System.DateTime.Now.ToString();
		date = date.Replace("/", "-");
		date = date.Replace(" ", "_");
		date = date.Replace(":", "-");
		ScreenCapture.CaptureScreenshot(Application.dataPath + "/Data/Screenshots/" + date + ".png");
	}
}