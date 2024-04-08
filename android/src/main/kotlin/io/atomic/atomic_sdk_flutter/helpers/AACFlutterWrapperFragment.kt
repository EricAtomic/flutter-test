package io.atomic.atomic_sdk_flutter.helpers

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import androidx.fragment.app.Fragment

class AACFlutterWrapperFragment : Fragment() {

  companion object {
    // View ID is required because Android doesn't assign an ID when the view is created programmatically
    var ID = 2843828
  }

  override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?,
    savedInstanceState: Bundle?): View {
    val layout = FrameLayout(requireContext())

    val layoutParams = FrameLayout.LayoutParams(
      ViewGroup.LayoutParams.WRAP_CONTENT,
      ViewGroup.LayoutParams.WRAP_CONTENT
    )
    layout.layoutParams = layoutParams
    layout.id = ID++

    return layout
  }
}