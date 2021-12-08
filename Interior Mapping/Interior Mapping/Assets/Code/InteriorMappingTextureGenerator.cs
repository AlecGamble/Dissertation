using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class InteriorMappingTextureGenerator : MonoBehaviour
{
     [SerializeField] private Vector2Int m_Resolution = new Vector2Int(2048, 2048);
     private Camera m_Camera;
 
     public string ScreenShotName() {
        string name = "";
        string date = System.DateTime.Now.ToString();
        date = date.Replace("/","-");
        date = date.Replace(" ","_");
        date = date.Replace(":","-");
        name += date;
        return name;
     }
    [ContextMenu("Take Screenshot")]
     public void TakeScreenshot()
     {
         if(!GetCamera()) return;

        RenderTexture renderTexture = RenderTexture.GetTemporary(m_Resolution.x, m_Resolution.y, 24);
        Texture2D screenShot = new Texture2D(m_Resolution.x, m_Resolution.y, TextureFormat.RGB24, false);

        m_Camera.targetTexture = renderTexture;
        m_Camera.Render();
        screenShot.ReadPixels(new Rect(0, 0, m_Resolution.x, m_Resolution.y), 0, 0);
        m_Camera.targetTexture = null;
        renderTexture.Release();

        byte[] bytes = screenShot.EncodeToPNG();
        // string filePath = Application.persistentDataPath + "/Data/Textures/InteriorMaps/" + ScreenShotName() + ".png";
        string filePath = Application.persistentDataPath + "file.png";
        System.IO.File.WriteAllBytes(filePath, bytes);
     }

     public bool GetCamera()
     {
         if(m_Camera != null) return true;
         m_Camera = GetComponent<Camera>();
         if(m_Camera != null) return true;
         Debug.LogError("[InteriorMappingTextureGenerator] This script must be attached to a camera");
         return false;
     }
 }