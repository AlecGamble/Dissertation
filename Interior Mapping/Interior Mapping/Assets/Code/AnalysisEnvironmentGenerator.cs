using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class AnalysisEnvironmentGenerator : MonoBehaviour
{
    [SerializeField] public GameObject m_BuildingPrefab;

    [SerializeField] private Vector2Int m_Layout;
    [SerializeField] private Vector2 m_Spacing;
    [SerializeField] private Vector2 m_BuildingLayout;
    [SerializeField] private bool m_RandomiseSeed;

    [Sirenix.OdinInspector.Button]
    private void Generate()
    {
        foreach(Transform t in transform)
        {
            DestroyImmediate(t.gameObject);
        }

        for(int x = 0; x < m_Layout.x; x++)
        {
            for(int y = 0; y < m_Layout.y; y++)
            {
                Vector3 position = new Vector3(- m_Layout.x * m_Spacing.x / 2 + x * m_Spacing.x, m_BuildingPrefab.transform.position.y, y * m_Spacing.y);
                Quaternion rotation = m_BuildingPrefab.transform.rotation;
                GameObject go = GameObject.Instantiate(m_BuildingPrefab, position, rotation, transform);

                if(m_RandomiseSeed)
                {
                    Material mat = go.GetComponent<MeshRenderer>().material;
                    Vector4 layout = new Vector4(m_BuildingLayout.x, m_BuildingLayout.y, m_RandomiseSeed ? Random.Range(0.0f, 1000.0f) : 0, m_RandomiseSeed ? Random.Range(0.0f, 1000.0f) : 0);
                    mat.SetVector("_Rooms", layout);
                }
            }
        }
    }

    private void OnEnable()
    {
        Application.targetFrameRate = -1;
        QualitySettings.vSyncCount = 0;
    }
}

// novel combination room maps and raymarching signed distance fields