using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RenderingAnalysisInfo : MonoBehaviour
{
    [SerializeField] private  float m_SampleDuration = 5.0f;
    [SerializeField] private  int m_SampleCount = 10;
    [SerializeField] private TMPro.TMP_Text[] m_Readings;
    [SerializeField] private TMPro.TMP_Text m_ReadingPrefab;

    private bool m_Sampling = false;

    [Sirenix.OdinInspector.Button]
    public void StartSampling()
    {
        StartCoroutine(Sample());
    }

    private IEnumerator Sample()
    {
        foreach(TMPro.TMP_Text text in m_Readings)
        {
            Destroy(text.gameObject);
        }

        m_Readings = new TMPro.TMP_Text[m_SampleCount];

        for(int i = 0; i < m_SampleCount; i++)
        {
            m_Readings[i] = Instantiate(m_ReadingPrefab, transform);
            m_Readings[i].text = "["+(i+1)+"]:";
        }

        for(int i = 0; i < m_SampleCount; i++)
        {
            float elapsed = 0.0f;
            int frames = 0;

            while(elapsed < m_SampleDuration)
            {
                elapsed += Time.unscaledDeltaTime;
                frames ++;
                yield return null;
            }

            float fps = frames / m_SampleDuration;
            m_Readings[i].text =  "[" + (i+1) + "]" + (1000/fps) + " ms";
        }
    }
}
