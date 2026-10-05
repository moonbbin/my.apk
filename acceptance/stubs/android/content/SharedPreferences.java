package android.content;

import java.util.Map;
import java.util.Set;

/**
 * 独立验收用的最小 {@code android.content.SharedPreferences}。
 *
 * 为什么需要它：真机上 {@code UserPreference} / {@code HistoryRepository} 都持有一个
 * {@code SharedPreferences} 字段。裸 JVM 里只要**触碰**这两个类（哪怕是反射读一个
 * `const val`），JVM 在类初始化 / 链接阶段就要解析这个字段的类型 ——
 * 桩里没有它，就会 `NoClassDefFoundError: android/content/SharedPreferences`，
 * 整段验收直接红（实测踩过）。
 *
 * 这里只提供**方法签名**，不提供实现：
 * 验收路径上 `prefs` 恒为 null（没有 Context 就没有 SharedPreferences），
 * 两个类都走"内存兜底"分支，压根不会调到这些方法。
 *
 * 只用于 acceptance 验收，不参与 APK 打包。
 */
public interface SharedPreferences {

    Map<String, ?> getAll();

    String getString(String key, String defValue);

    Set<String> getStringSet(String key, Set<String> defValues);

    int getInt(String key, int defValue);

    long getLong(String key, long defValue);

    float getFloat(String key, float defValue);

    boolean getBoolean(String key, boolean defValue);

    boolean contains(String key);

    Editor edit();

    void registerOnSharedPreferenceChangeListener(OnSharedPreferenceChangeListener listener);

    void unregisterOnSharedPreferenceChangeListener(OnSharedPreferenceChangeListener listener);

    /** 写入器。 */
    interface Editor {

        Editor putString(String key, String value);

        Editor putStringSet(String key, Set<String> values);

        Editor putInt(String key, int value);

        Editor putLong(String key, long value);

        Editor putFloat(String key, float value);

        Editor putBoolean(String key, boolean value);

        Editor remove(String key);

        Editor clear();

        boolean commit();

        void apply();
    }

    /** 变更监听器。 */
    interface OnSharedPreferenceChangeListener {
        void onSharedPreferenceChanged(SharedPreferences sharedPreferences, String key);
    }
}
