using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Sirenix.OdinInspector;

public class InteriorMappingTextureGenerator : MonoBehaviour
{
     [SerializeField] private Vector2Int m_Resolution = new Vector2Int(2048, 2048);
     [SerializeField][FolderPath(ParentFolder = "Assets")] private string m_Path = "/Data/Textures/Renders";
     [SerializeField] private string m_Prefix;
     private string Path { get { return Application.dataPath + "/" + m_Path + "/"; } }
     private Camera m_Camera;

     public enum NameType { Date, Id };
     [SerializeField] private NameType m_NameType = NameType.Id;

     [SerializeField][ShowIf("@m_NameType == NameType.Id")] private int m_Id = 0;

     public string Name 
     {
         get
         {
             switch(m_NameType)
             {
                 case NameType.Date:
                    return System.DateTime.Now.ToString().Replace("/","-").Replace(" ","_").Replace(":","-");
                case NameType.Id:
                    return m_Id.ToString();
                default:
                    return "";
                
             }
         }
     }
 

    [Button("Capture")]
     public void TakeScreenshot()
     {
        if(!GetCamera()) 
        {
            return;
        }
        if(!System.IO.Directory.Exists(Path)) 
        {
            Debug.LogWarning("[InteriorMappingTextureGenerator::TakeScreenshot] No directory exists at path: " + Path);
            return;
        }
        if(System.IO.File.Exists(Path + m_Prefix + Name + ".png")) 
        {
            Debug.LogWarning("[InteriorMappingTextureGenerator::TakeScreenshot] File already exists: " + Path + Name + ".png");
            return;
        }
        RenderTexture originalRT = RenderTexture.active;

        // Render to render texture
        RenderTexture renderTexture = RenderTexture.GetTemporary(m_Resolution.x, m_Resolution.y, 24);
        Texture2D screenShot = new Texture2D(m_Resolution.x, m_Resolution.y, TextureFormat.RGB24, false);
        m_Camera.targetTexture = renderTexture;
        m_Camera.Render();

        RenderTexture.active = renderTexture;

        screenShot.ReadPixels(new Rect(0, 0, m_Resolution.x, m_Resolution.y), 0, 0);
        screenShot.Apply();
        m_Camera.targetTexture = null;
        renderTexture.Release();

        byte[] bytes = screenShot.EncodeToPNG();
        string filePath = Path + m_Prefix + Name + ".png";
        System.IO.File.WriteAllBytes(filePath, bytes);

        if(m_NameType == NameType.Id) m_Id ++;
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