using UnityEngine;
using UnityEditor;

public class ScreenshotTaker
{
	[MenuItem("Screen/Capture Screenshot")]
	public static void CaptureScreenshot()
	{
		string date = System.DateTime.Now.ToString();
		date = date.Replace("/", "-");
		date = date.Replace(" ", "_");
		date = date.Replace(":", "-");
		Debug.Log(Application.dataPath + "/Data/Screenshots/" + date + ".png");
		ScreenCapture.CaptureScreenshot(Application.dataPath + "/Data/Screenshots/" + date + ".png");
	}
}